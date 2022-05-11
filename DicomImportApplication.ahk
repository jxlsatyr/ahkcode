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
; 每1分钟查询是否有影像导出完成的任务
SetTimer, DicomImport, 60000

DicomImport:
SQL := "SELECT id, tenant_id, project_id, src_accno, dst_args, zip_file_path, version FROM t_dicom_export WHERE is_deleted = 0 AND status = 6 AND decrypted = 0 AND dst_type = 'toMoveR' ORDER BY create_time ASC LIMIT 10"
Objs := Query(SQL)
Loop % Objs.Length()
{
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
	Rows :=  Update(SQL)
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