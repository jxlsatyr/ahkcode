#Persistent
#SingleInstance, Force
SetBatchLines, -1
#Include DicomDecrypt.ahk
#Include PrDecrypt.ahk
#Include MySQL.ahk
#Include JSON.ahk
#Include HTTPRequest.ahk

; 7-Zip解压工具路径
7Zip := "C:\Program Files\7-Zip\7z.exe"
; 每5分钟查询是否有待处理的项目
SetTimer, DicomExport, 300000
; 每1分钟查询是否有影像导出完成的任务
SetTimer, DicomImport, 60000
; 每5分钟查询是否有PR导出完成的任务
SetTimer, PRImport, 300000

; 每10分钟查询影像导出是否完成
SetTimer, DicomImportComplete, 600000
; 每10分钟查询PR导出是否完成
SetTimer, PRImportComplete, 600000
return

DicomImportComplete:
SQL := "SELECT id, project_id, version FROM t_dicom_migration WHERE is_deleted = 0 AND STATUS = 5 ORDER BY create_time desc LIMIT 10"
Objs := Query(SQL)
Loop % Objs.Length() {
	ID := Objs[A_Index].id
	if (!ID) {
		return
	}
	ProjectID := Objs[A_Index].project_id
	Version := Objs[A_Index].version
	; 影像导出数量
	SQL := "SELECT Count(1) FROM t_dicom_export WHERE is_deleted = 0 AND dst_type = 'toMoveR' AND project_id = '" ProjectID "'"
	ExportNum := Count(SQL)
	; 影像导入数量
	SQL := "SELECT Count(1) FROM t_dicom_export WHERE is_deleted = 0 AND status = 6 AND dst_type = 'toMoveImp' AND project_id = '" ProjectID "'"
	ImportNum := Count(SQL)
	if (ExportNum = ImportNum) {
		SQL := "UPDATE t_dicom_migration SET status = 6, version = version + 1, update_time = now() WHERE id = '" ID "' AND version = " Version
		Update(SQL)
	}
}
return

PRImportComplete:
SQL := "SELECT id, project_id, version FROM t_dicom_migration WHERE is_deleted = 0 AND STATUS = 6 ORDER BY create_time desc LIMIT 10"
Objs := Query(SQL)
Loop % Objs.Length() {
	ID := Objs[A_Index].id
	if (!ID) {
		return
	}
	ProjectID := Objs[A_Index].project_id
	Version := Objs[A_Index].version
	; 影像导出数量
	SQL := "SELECT id, zip_file_path FROM t_dicom_export WHERE is_deleted = 0 AND status = 6 AND dst_type = 'toMovePr' AND decrypted = 1 AND project_id = '" ProjectID "'"
	ExportObjs := Query(SQL)
	ID := ExportObjs[1].id
	if (!ID) {
		return
	}
	ZipFilePath := StrReplace(StrReplace(ExportObjs[1].zip_file_path, "/data/eimage", "z:"), "/", "\") "\dcm\"
	ExportNum := 0 
	Loop, Files, %ZipFilePath%, D {
		ExportNum++
	}
	; 影像导入数量
	SQL := "SELECT Count(1) FROM t_dicom_export WHERE is_deleted = 0 AND status = 6 AND dst_type = 'toMovePrImp' AND project_id = '" ProjectID "'"
	ImportNum := Count(SQL)
	if (ExportNum = ImportNum) {
		SQL := "UPDATE t_dicom_migration SET status = 7, version = version + 1, update_time = now() WHERE id = '" ID "' AND version = " Version
		Update(SQL)
	}
}
return

PRImport:
SQL := "SELECT id, tenant_id, project_id, src_accno, version FROM t_dicom_export WHERE is_deleted = 0 AND status = 6 AND decrypted = 0 AND dst_type = 'toMoveR' ORDER BY create_time ASC LIMIT 10"
Objs := Query(SQL)
Loop % Objs.Length() {
	ID := Objs[A_Index].id
	if (!ID) {
		return
	}
	ID := Objs[A_Index].id
	TenantID := Objs[A_Index].tenant_id
	ProjectID := Objs[A_Index].project_id
	SrcAccno := Objs[A_Index].src_accno
	Version := Objs[A_Index].version
	
	SQL := "SELECT zip_file_path FROM t_dicom_export WHERE is_deleted = 0 AND status = 6 AND dst_type = 'toMovePr' AND project_id = '" ProjectID "'"
	Objs := Query(SQL)
	if (Objs.Length() <= 0) {
		return
	}
	ZipFilePath := Objs[1].zip_file_path
	if (!ZipFilePath) {
		return
	}
	; 当前访视开始解密
	SQL := "UPDATE t_dicom_export SET decrypted = 1, version = version + 1, update_time = now() WHERE id = '" ID "' AND version = " Version
	Rows := Update(SQL)
	if (Rows > 0) {
		; 需要解压的文件路径
		ZipFilePath := StrReplace(StrReplace(ZipFilePath, "/data/eimage", "z:"), "/", "\") 
		SrcPath := ZipFilePath "\dcm\" SrcAccno
		DecryptPath := ZipFilePath "\dcm_decoded\" SrcAccno
		Obj := new PrDecrypt(TenantID, ProjectID, SrcPath, DecryptPath, SrcAccno)
		obj.Start()
	}
}
return

DicomImport:
SQL := "SELECT id, tenant_id, project_id, src_accno, dst_args, zip_file_path, version FROM t_dicom_export WHERE is_deleted = 0 AND status = 6 AND decrypted = 0 AND dst_type = 'toMoveR' ORDER BY create_time ASC LIMIT 10"
Objs := Query(SQL)
Loop % Objs.Length() {
	ID := Objs[A_Index].id
	if (!ID) {
		return
	}
	TenantID := Objs[A_Index].tenant_id
	ProjectID := Objs[A_Index].project_id
	ACCNO := Objs[A_Index].src_accno
	DstArgs := JSON.Load(Objs[A_Index].dst_args)
	ZipFilePath := JSON.Load(Objs[A_Index].zip_file_path)
	Version := Objs[A_Index].version
	; 当前访视开始解密
	SQL := "UPDATE t_dicom_export SET decrypted = 1, version = version + 1, update_time = now() WHERE id = '" ID "' AND version = " Version
	Rows := Update(SQL)
	if (Rows > 0) {
		; 需要解压的文件路径
		ZipFilePath := StrReplace(StrReplace(ZipFilePath[1].filePath, "/data/eimage", "z:"), "/", "\")
		; 解压至文件路径
		SrcPath := "D:\" ProjectID "\source"
		
		; 1.解压
		DirName := StrReplace(DstArgs.fileNameOfZip, ".zip")
		SrcPath := SrcPath "\" DirName
		RunWait , % 7Zip " x -y  -o" SrcPath " " ZipFilePath 
		
		; 2.解密
		Obj := new DicomDecrypt(TenantID, ProjectID, DirName, ACCNO, "toMoveR")
		obj.Start()
	}
}
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
	; 
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
