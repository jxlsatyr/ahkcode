#SingleInstance, Force
#Include MySQL.ahk

class Decrypt {

	; 7-Zip解压工具路径
	static 7Zip := "C:\Program Files\7-Zip\7z.exe"
	; EBM解密工具路径
	static DecryptDICOMTools := "C:\Users\tm_adminuser\Desktop\D2New\DecryptDICOMTools.exe"
	; 解密进度监控
	timer := ObjBindMethod(this, "Compress")

	__New(ProjectId, DirName) {
		; 解压至文件路径
		this.SrcPath := "D:\" ProjectId "\source\" DirName
		; 解密至文件路径
		this.DecryptPath := "D:\" ProjectId "\decrypt\" DirName
		; 打包至文件路径
		this.UploadPath := "Z:\ebm_data\upload\" ProjectId "\" DirName ".zip"
	}
	
	Start() {
		; 2.解密
		Run, % this.DecryptDICOMTools,,,PID
		WinWait, ahk_pid %PID%
		this.PID := PID
		SrcPath := this.SrcPath
		DecryptPath := this.DecryptPath
		ControlSetText, WindowsForms10.EDIT.app.0.141b42a_r12_ad13, %SrcPath%, ahk_pid %PID%
		ControlSetText, WindowsForms10.EDIT.app.0.141b42a_r12_ad12, %DecryptPath%, ahk_pid %PID%
		SetControlDelay -1  ; May improve reliability and reduce side effects.
		ControlClick, WindowsForms10.BUTTON.app.0.141b42a_r12_ad11, ahk_pid %PID%,,,, NA
		timer := this.timer
		SetTimer, % timer, 10000
	}
	
	Compress() {
		PID := this.PID
		ControlGetText, OutputVar, WindowsForms10.EDIT.app.0.141b42a_r12_ad11, ahk_pid %PID%
		If RegExMatch(OutputVar, "共轉換\d+筆,完成\d+筆",, -50)
		{
			SetTimer,, Off  ; 即此处计时器关闭自己.
			WinClose, ahk_pid %PID%
			
			; 3.打包到指定目录
			RunWait , % this.7Zip " a -mx1 -tzip " this.UploadPath " " this.DecryptPath "\*"
			
			; 调用导入微云接口
			URL := "http://10.1.1.100:8022/dicomExport/exportAllDicomToMoveR"
			HttpObj := ComObjCreate("WinHttp.WinHttpRequest.5.1")
			HttpObj.Open("POST", URL)
			HttpObj.SetRequestHeader("Content-Type", "application/json")
			Body := {"realDo":true,"srcProject":{"tenantId":TenantID,"projectId":ProjectID},"taskId":TaskID}
			HttpObj.Send(Body)
			Result := HttpObj.ResponseText
			Accnos := ""
			if (Result.status != 0) {
				MsgBox, 调用导入微云接口失败
			} 
		}
		return
	}
}