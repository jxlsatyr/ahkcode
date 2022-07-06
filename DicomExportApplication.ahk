SetBatchLines, -1
#Include MySQL.ahk
#Include JSON.ahk
#Include HTTPRequest.ahk

if !WinExist("ahk_exe Xshell.exe") {
	MsgBox, 未检测到Xshell客户端
	return
}
; 查询等待影像导出的项目
SQL := "SELECT id, task_id,	target_shard, remark, tenant_id, project_id, version FROM t_dicom_migration WHERE is_deleted = 0 AND STATUS = 0"
Objs := Query(SQL)
Loop % Objs.Length()
{
	ID := Objs[A_Index].id
	if (!ID) {
		return
	}
	TaskID := Objs[A_Index].task_id
	TargetShard := Objs[A_Index].target_shard
	Remark := Objs[A_Index].remark
	TenantID := Objs[A_Index].tenant_id
	ProjectID := Objs[A_Index].project_id
	Version := Objs[A_Index].version
	; NAS目录创建中
	SQL := "UPDATE t_dicom_migration SET status = 1, version = version + 1, update_time = now() WHERE id = '" ID "' AND version = " Version
	Rows := Update(SQL)
	if (Rows <= 0) {
		return
	}
	; 更新项目升级状态
	GET("http://10.1.0.228:8086/project/config/upgrade/1/"ProjectID)
	WinActivate, ahk_exe Xshell.exe
	Send, mkdir /data/eimage/ebm_data/upload/%ProjectId%{enter}
	Sleep, 500
	Send, chmod 777 -R /data/eimage/ebm_data/upload/%ProjectId%{enter}
	Sleep, 500
	Send, mkdir -p /data/eimage/ebm_data_toMovePr/%ProjectId%/dcm_decoded{enter}
	Sleep, 500
	Send, mkdir -p /data/eimage/ebm_data_toMovePr/%ProjectId%/dcmRecoverFull_decoded{enter}
	Sleep, 500
	Send, chmod 777 -R /data/eimage/ebm_data_toMovePr/%ProjectId%{enter}
	Sleep, 500
	; 影像导出接口调用中
	SQL := "UPDATE t_dicom_migration SET status = 2, update_time = now() WHERE id = '" ID "'"
	Update(SQL)
	Body := JSON.Dump({"realDo":true,"srcProject":{"tenantId":TenantID,"projectId":ProjectID},"taskId":TaskID})
	Result := POST("http://10.1.1.100:8022/dicomExport/exportAllDicomToMoveR", Body)
	if (Result.success) {
		; 更新项目配置
		SQL := "UPDATE t_dicom_migration SET status = 3, update_time = now() WHERE id = '" ID "'"
		Update(SQL)
		SQL := "UPDATE project_config SET image_vendor = 'weiyun', target_shard = '" TargetShard "', enable_screenshot = 1, enable_scale_in_view = 1 where project_id = '" ProjectID "'"
		Update(SQL)
		SQL := "UPDATE dicom SET orig_ebm_shard = ebm_shard WHERE is_deleted = 0 AND orig_ebm_shard is null AND project_id = '" ProjectID "'"
		Update(SQL)
		SQL := "UPDATE dicom SET image_vendor = 'weiyun', ebm_shard = '" TargetShard "' WHERE is_deleted = 0 AND project_id = '" ProjectID "'"
		Update(SQL)
		SQL := "UPDATE dicom SET src_accno = null WHERE is_deleted = 0 AND inner_flag = 1 AND inner_type = 1 AND project_id = '" ProjectID "'"
		Update(SQL)
		; 更新项目配置缓存
		GET("http://10.1.0.228:8086/project/config/cleanAllCache")
		; 标记导出接口调用中
		SQL := "UPDATE t_dicom_migration SET status = 4, update_time = now() WHERE id = '" ID "'"
		Update(SQL)
		Body := JSON.Dump({"realDo":true,"srcProject":{"tenantId":TenantID,"projectId":ProjectID},"taskId":TaskID})
		POST("http://10.1.1.100:8022/dicomExport/exportAllDicomToMovePr", Body)
		; 影像迁移中
		SQL := "UPDATE t_dicom_migration SET status = 5, update_time = now() WHERE id = '" ID "'"
		Update(SQL)
	}
	; 调用导出接口失败，等待人工介入
	else { 
		SQL := "UPDATE t_dicom_migration SET remark = '" SubStr(Result, 1, 500) "', update_time = now() WHERE id = '" ID "'"
		Update(SQL)
	}
}