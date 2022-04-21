#Persistent
#SingleInstance, Force
SetBatchLines, -1
#Include Decrypt.ahk
#Include MySQL.ahk

; 7-Zip解压工具路径
7Zip := "C:\Program Files\7-Zip\7z.exe"
; 每10分钟查询是否有待处理的项目
SetTimer, Start, 600000
; 每5分钟查询是否有导出完成的任务
SetTimer, Main, 300000
return

Main:
SQL := "SELECT id, project_id, zip_file_path, version FROM t_dicom_export WHERE is_deleted = 0 AND status = 6 AND decrypted = 0 AND dst_type = 'toMoveR' ORDER BY create_time ASC LIMIT 10"
Objs := Query(SQL)
Loop % Objs.Length() {
	ID := Objs[A_Index].id
	ProjectID := Objs[A_Index].project_id
	ZipFilePath := Objs[A_Index].zip_file_path
	Version := Objs[A_Index].version
	; 当前访视开始解密
	SQL := "UPDATE t_dicom_export_copy SET decrypted = 1, version = version + 1, update_time = now() WHERE id = '" ID "' AND version = " Version
	Rows := Update(SQL)
	if (Rows > 0) {
		; 需要解压的文件路径
		ZipFilePath := ZipFilePath[1].filePath
		; 解压至文件路径
		SrcPath := "D:\" ProjectID "\source"
		
		; 1.解压
		DirName := StrReplace(SubStr(ZipFilePath, InStr(ZipFilePath, "/",,-1 ) +1), ".zip")
		SrcPath := SrcPath "\" DirName
		RunWait , % 7Zip " x -y  -o" SrcPath " " ZipFilePath 
		
		; 2.解密
		Obj := new Decrypt(ProjectID, DirName)
		obj.Start()
	}
}
return

Start:
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
WinActivate
;~ Send, mkdir /data/eimage/ebm_data/download/%ProjectId%  {enter}
;~ Send, chmod 777 -R /data/eimage/ebm_data/download/%ProjectId%  {enter}
Send, mkdir /data/eimage/ebm_data/upload/%ProjectId%  {enter}
Send, chmod 777 -R /data/eimage/ebm_data/upload/%ProjectId%  {enter}
; 影像导出接口调用中
SQL := "UPDATE t_dicom_migration SET status = 2, update_time = now() WHERE id = '" ID "'
Update(SQL)
URL := "http://10.1.1.100:8022/dicomExport/exportAllDicomToMoveR"
HttpObj := ComObjCreate("WinHttp.WinHttpRequest.5.1")
HttpObj.Open("POST", URL)
HttpObj.SetRequestHeader("Content-Type", "application/json")
Body := {"realDo":true,"srcProject":{"tenantId":TenantID,"projectId":ProjectID},"taskId":TaskID}
HttpObj.Send(Body)
Result := HttpObj.ResponseText
Accnos := ""
if (Result.status = 0) {
	Failed := Result.failed
	Loop % Failed.Length() {
	Message := Failed[A_Index].message
	RegExMatch(Message, "\w+$", Accno)
	if (Accnos = "") {
		Accnos := Accno
	} else {
		Accnos := Accnos ", " Accno
	}
	SQL := "UPDATE t_dicom_migration SET status = 3, reamark = '" Accnos "', update_time = now() WHERE id = '" ID "'
	Update(SQL)
} 
; 调用导出接口失败，等待人工介入
else {
	SQL := "UPDATE t_dicom_migration SET remark = '" SubStr(Result, 1, 500) "', update_time = now() WHERE id = '" ID "'
	Update(SQL)
	MsgBox % Result
}
return


; 查询并返回对象数组
Query(Sql) {
	global My_DB
	Objs := []
	If (My_DB.Query(Sql) = MySQL_SUCCESS) {
		Result := My_DB.GetResult()
		Loop, % Result.MaxIndex() {
			Row := Result[A_Index]
			Obj := {}
			Loop, % Row.MaxIndex() {
				Key := Result.Fields[A_Index].Name
				Val := Row[A_Index]
				Obj[Key] := Val
			}
			Objs.Push(Obj)
		}
	} Else {
		MsgBox, 16, MySQL Error!, % My_DB.ErrNo() . ": " . My_DB.Error()
	}
	return Objs
}

; 更新并返回更新记录数
Update(Sql) {
	global My_DB
	Rows := 0
	If (My_DB.Query(SQL) = MySQL_SUCCESS) {
		Rows := My_DB.Affected_Rows()
	} Else {
		MsgBox, 16, MySQL Error!, % My_DB.ErrNo() . ": " . My_DB.Error()
	}
	return Rows
}
