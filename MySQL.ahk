#Include MySQLAPI.ahk

Global MySQL_SUCCESS := 0
; ======================================================================================================================
; Settings
; ======================================================================================================================
UserID := "mirs_user"           ; User name - must have privileges to create databases
UserPW := "mirs_user@2018+"           ; User''s password
Server := "prod-mysql-mirs-dmp.taimei.com"      ; Server''s host name or IP address
Database := "mirs"         ; Name of the database to work with
Port := "3310"
; ======================================================================================================================
; Connect to MySQL
; ======================================================================================================================
If !(My_DB := New MySQLAPI)
   ExitApp
ClientVersion := My_DB.Get_Client_Info()
If !My_DB.Real_Connect(Server, UserID, UserPW, Database, Port) {
   MsgBox, 16, MySQL Error!, % "Connection failed!`r`n" . My_DB.ErrNo() . " - " . My_DB.Error()
   ExitApp
}
	
; 查询并返回对象数组
Query(SQL) {
	global My_DB
	Objs := []
	If (My_DB.Query(SQL) = MySQL_SUCCESS) {
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
		MsgBox, 16, MySQL Error!, % My_DB.ErrNo() . ": " . My_DB.Error() ": " SQL
	}
	return Objs
}

; 更新并返回更新记录数
Update(SQL) {
	global My_DB
	Rows := 0
	If (My_DB.Query(SQL) = MySQL_SUCCESS) {
		Rows := My_DB.Affected_Rows()
	} Else {
		MsgBox, 16, MySQL Error!, % My_DB.ErrNo() . ": " . My_DB.Error() ": " SQL
	}
	return Rows
}

; 计数
Count(SQL) {
	global My_DB
	Num := 0
	If (My_DB.Query(SQL) = MySQL_SUCCESS) {
		Result := My_DB.Store_Result()
		Row := My_DB.Fetch_Row(Result)
		Num := StrGet(NumGet(Row + 0, 0, "UPtr"), "UTF-8")
		My_DB.Free_Result(Result)
	} Else {
		MsgBox, 16, MySQL Error!, % My_DB.ErrNo() . ": " . My_DB.Error() ": " SQL
	}
	return Num
}