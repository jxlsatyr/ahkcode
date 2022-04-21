#Persistent
#SingleInstance, Force
SetBatchLines, -1
#Include Decrypt.ahk
#Include MySQLAPI.ahk

Global MySQL_SUCCESS := 0
; ======================================================================================================================
; Settings
; ======================================================================================================================
UserID := "root"           ; User name - must have privileges to create databases
UserPW := "123456"           ; User''s password
Server := "192.168.105.106"      ; Server''s host name or IP address
Database := "mirs"         ; Name of the database to work with
; ======================================================================================================================
; Connect to MySQL
; ======================================================================================================================
If !(My_DB := New MySQLAPI)
   ExitApp
ClientVersion := My_DB.Get_Client_Info()
If !My_DB.Connect(Server, UserID, UserPW) {
   MsgBox, 16, MySQL Error!, % "Connection failed!`r`n" . My_DB.ErrNo() . " - " . My_DB.Error()
   ExitApp
}
; Select the database as default
My_DB.Select_DB(Database)

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
