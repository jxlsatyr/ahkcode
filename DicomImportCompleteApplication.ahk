#Persistent
#SingleInstance, Force
SetBatchLines, -1
#Include MySQL.ahk
#Include JSON.ahk
#Include HTTPRequest.ahk

; 每10分钟查询影像导出是否完成
SetTimer, DicomImportComplete, 600000

DicomImportComplete:
SQL := "SELECT id, project_id, version FROM t_dicom_migration WHERE is_deleted = 0 AND STATUS = 5 ORDER BY create_time desc"
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
	SQL := "SELECT Count(DISTINCT src_accno) FROM t_dicom_export WHERE is_deleted = 0 AND dst_type IN ('toMoveR','toMoveRecoverExp') AND project_id = '" ProjectID "'"
	ExportNum := Count(SQL)
	; 影像导入数量
	SQL := "SELECT Count(DISTINCT src_accno) FROM t_dicom_export WHERE is_deleted = 0 AND status IN (6, 16) AND dst_type IN ('toMoveImp','toMoveRecoverImp') AND project_id = '" ProjectID "'"
	ImportNum := Count(SQL)
	if (ExportNum = ImportNum) {
		SQL := "UPDATE t_dicom_migration SET status = 6, version = version + 1, update_time = now() WHERE id = '" ID "' AND version = '" Version "'"
		Update(SQL)
	}
}
return