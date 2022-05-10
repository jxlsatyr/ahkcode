#Persistent
#SingleInstance, Force
SetBatchLines, -1
#Include DicomDecrypt.ahk
#Include PrDecrypt.ahk
#Include MySQL.ahk
#Include JSON.ahk
#Include HTTPRequest.ahk

; 每5分钟查询是否有待处理的项目
SetTimer, DicomExport, 300000
return

DicomExport:
; 查询等待影像导出的项目
SQL := "SELECT id, task_id,	target_shard, remark, tenant_id, project_id, version FROM t_dicom_migration WHERE is_deleted = 0 AND STATUS = 0 LIMIT 1"
Objs := Query(SQL)
if Objs.Length() <= 0 {
	return
} 
ID := Objs[1].id
TaskID := Objs[1].task_id
TargetShard := Objs[1].target_shard
Remark := Objs[1].remark
TenantID := Objs[1].tenant_id
ProjectID := Objs[1].project_id
Version := Objs[1].version
if !WinExist("ahk_exe Xshell.exe") {
	MsgBox, 未检测到Xshell客户端
	return
}
; NAS目录创建中
SQL := "UPDATE t_dicom_migration SET status = 1, version = version + 1, update_time = now() WHERE id = '" ID "' AND version = " Version
Rows := Update(SQL)
if (Rows <= 0) {
	return
}
; 更新项目升级状态
GET("http://10.1.0.228:8086/project/config/upgrade/1/"ProjectID)
WinActivate, ahk_exe Xshell.exe
Send, mkdir /data/eimage/ebm_data/upload/%ProjectId%  {enter}
Sleep, 1000
Send, chmod 777 -R /data/eimage/ebm_data/upload/%ProjectId%  {enter}
Sleep, 1000
; 影像导出接口调用中
SQL := "UPDATE t_dicom_migration SET status = 2, update_time = now() WHERE id = '" ID "'"
Update(SQL)
Body := JSON.Dump({"realDo":true,"srcProject":{"tenantId":TenantID,"projectId":ProjectID},"taskId":TaskID})
POST("http://10.1.1.100:8022/dicomExport/exportAllDicomToMoveR", Body)
Result := JSON.Load(HttpObj.ResponseText)
if (Result.success) {
	; 更新项目配置
	SQL := "UPDATE t_dicom_migration SET status = 3, update_time = now() WHERE id = '" ID "'"
	Update(SQL)
	SQL := "UPDATE project_config SET image_vendor = 'weiyun', target_shard = '" TargetShard "', enable_screenshot = 1, enable_scale_in_view = 1 where project_id = '" ProjectID "'"
	Update(SQL)
	SQL := "UPDATE dicom SET image_vendor = 'weiyun', orig_ebm_shard = ebm_shard, ebm_shard = '" TargetShard "' WHERE is_deleted = 0 AND project_id = '" ProjectID "'"
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
	
	WinActivate, ahk_exe Xshell.exe
	Send, mkdir -p /data/eimage/ebm_data_toMovePr/%ProjectId%/dcm_decoded  {enter}
	Sleep, 1000
	Send, chmod 777 -R /data/eimage/ebm_data_toMovePr/%ProjectId%  {enter}
	Sleep, 1000
}
; 调用导出接口失败，等待人工介入
else { 
	SQL := "UPDATE t_dicom_migration SET remark = '" SubStr(Result, 1, 500) "', update_time = now() WHERE id = '" ID "'"
	Update(SQL)
	;~ MsgBox % 调用导出接口失败：Result
}
return
