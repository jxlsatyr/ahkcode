#Include JSON.ahk

Global HttpObj := ComObjCreate("WinHttp.WinHttpRequest.5.1")

; GET请求
GET(URL) {
	HttpObj.Open("GET", URL)
	HttpObj.SetRequestHeader("Content-Type", "application/json")
	HttpObj.Send()
	;~ Result := JSON.Load(HttpObj.ResponseText)
	;~ if (!Result.success)  {
		;~ MsgBox % 调用导出接口失败：Result
	;~ } 
}

; POST请求
POST(URL, Body) {
	HttpObj.Open("POST", URL)
	HttpObj.SetRequestHeader("Content-Type", "application/json")
	HttpObj.Send(Body)
	;~ Result := JSON.Load(HttpObj.ResponseText)
	;~ if (!Result.success)  {
		;~ MsgBox % 调用导出接口失败：Result
	;~ } 
}