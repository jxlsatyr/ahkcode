#Include MySQL.ahk
#Include JSON.ahk
#Include HTTPRequest.ahk

SQL := "SELECT id, project_id, src_accno FROM t_dicom_export WHERE is_deleted = 0 AND dst_type = 'toMoveImp' AND status = 9 AND length( remark ) > 400"
Objs := Query(SQL)
Loop % Objs.Length()
{
	ID := Objs[A_Index].id
	if (!ID) {
		return
	}
	ProjectID := Objs[A_Index].project_id
	ACCNO := Objs[A_Index].src_accno
	SQL := "UPDATE dicom SET ebm_shard = 'shard2' WHERE is_deleted = 0 AND project_id = '" ProjectID "' AND accno = '" ACCNO "'"
	Update(SQL)
	SQL := "UPDATE t_dicom_export SET is_deleted = 1, update_time = now(), version = version + 1 WHERE id = '" ID "'"
	Update(SQL)
	SQL := "UPDATE t_dicom_export SET decrypted = 0 WHERE is_deleted = 0 AND dst_type = 'toMoveR' AND project_id = '" ProjectID "' AND src_accno = '" ACCNO "'"
	Update(SQL)
	
}