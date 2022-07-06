#Persistent
#SingleInstance, Force
SetBatchLines, -1
#Include MySQL.ahk
#Include JSON.ahk
#Include HTTPRequest.ahk

; 每10分钟查询PR导出是否完成
SetTimer, PRImportComplete, 600000

PRImportComplete:
SQL := "SELECT id, project_id, version FROM t_dicom_migration WHERE is_deleted = 0 AND STATUS = 6 ORDER BY create_time desc"
Objs := Query(SQL)
Loop % Objs.Length()
{
	ID := Objs[A_Index].id
	if (!ID) {
		return
	}
	ProjectID := Objs[A_Index].project_id
	Version := Objs[A_Index].version
	; 影像导出数量
	SQL := "SELECT zip_file_path FROM t_dicom_export WHERE is_deleted = 0 AND status = 6 AND dst_type = 'toMovePr' AND project_id = '" ProjectID "'"
	ExportObjs := Query(SQL)
	ZipFilePath := StrReplace(StrReplace(ExportObjs[1].zip_file_path, "/data/eimage", "z:"), "/", "\") "\dcm\*"
	ExportNum := 0 
	Loop, Files, %ZipFilePath%, D
	{
		ExportNum++
	}
	; 影像导入数量
	SQL := "SELECT COUNT(DISTINCT src_accno) FROM t_dicom_export WHERE is_deleted = 0 AND status IN (6, 16) AND dst_type = 'toMovePrImp' AND project_id = '" ProjectID "'"
	ImportNum := Count(SQL)
	;~ MsgBox, % ProjectID
	;~ MsgBox, % ExportNum
	;~ MsgBox, % ImportNum
	if (ExportNum = ImportNum) {
		SQL := "UPDATE t_dicom_migration SET status = 7, version = version + 1, update_time = now() WHERE id = '" ID "' AND version = '" Version "'"
		Update(SQL)
		; 更新项目升级状态
		GET("http://10.1.0.228:8086/project/config/upgrade/0/"ProjectID)
	}
}
return