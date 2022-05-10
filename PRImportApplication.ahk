#Persistent
#SingleInstance, Force
SetBatchLines, -1
#Include DicomDecrypt.ahk
#Include PrDecrypt.ahk
#Include MySQL.ahk
#Include JSON.ahk
#Include HTTPRequest.ahk

; 每10分钟查询是否有PR导出完成的任务
SetTimer, PRImport, 10000

PRImport:
MySQL := new MySQL()
SQL := "SELECT id, tenant_id, project_id, src_accno, version FROM t_dicom_export WHERE is_deleted = 0 AND status = 6 AND decrypted = 0 AND dst_type = 'toMoveImp' ORDER BY create_time ASC LIMIT 10"
Objs := Query(SQL)
Loop % Objs.Length()
{
	ID := Objs[A_Index].id
	if (!ID) {
		return
	}
	TenantID := Objs[A_Index].tenant_id
	ProjectID := Objs[A_Index].project_id
	SrcAccno := Objs[A_Index].src_accno
	Version := Objs[A_Index].version
	
	SQL := "SELECT zip_file_path FROM t_dicom_export WHERE is_deleted = 0 AND status = 6 AND dst_type = 'toMovePr' AND project_id = '" ProjectID "'"
	Results := Query(SQL)
	if (Results.Length() <= 0) {
		return
	}
	ZipFilePath := Results[1].zip_file_path
	; 当前访视开始解密
	SQL := "UPDATE t_dicom_export SET decrypted = 1, version = version + 1, update_time = now() WHERE id = '" ID "' AND version = " Version
	Rows := Update(SQL)
	if (Rows > 0) {
		; 需要解压的文件路径
		ZipFilePath := StrReplace(StrReplace(ZipFilePath, "/data/eimage", "z:"), "/", "\") 
		SrcPath := ZipFilePath "\dcm\" SrcAccno
		if FileExist(SrcPath) {
			DecryptPath := ZipFilePath "\dcm_decoded\" SrcAccno
			Obj := new PrDecrypt(TenantID, ProjectID, SrcPath, DecryptPath, SrcAccno)
			obj.Start()
		}
	}
}
return