#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
; #Include %A_ScriptDir%/util/Adodb.ahk
; #Include %A_ScriptDir%/util/SmartZip.ahk

;;  DB测试
; a := new Adodb
; a.open("DSN=mysql.test;") ;到DSN里面配置了用户名密码则UID PWD不用配置。
; ret := a.sqlQuery("select * from t_mdm_form 
; order by create_time desc limit 1")
; a.Close()
; MsgBox % ObjMaxIndex(ret) " = " ret.MaxIndex()
; MsgBox, % ret.1.1
; ; MsgBox, % ret[1][1]


; 切换窗口
if WinExist("ahk_exe DecryptDICOMTools.exe")
{
    WinGet, tpid ,PID
    WinGet, texe ,ProcessName
    ; WinActivate
}
;ctrl+J 切换窗口
;;窗口激活 解密檔案工 DecryptDICOMTools.exe 
GroupAdd, ag ,ahk_exe %texe%

^k::
GroupActivate, ag ,R
return 

^j::
GroupActivate, ag ,R
return

^H::
WinGet ,count ,List  ,ahk_exe DecryptDICOMTools.exe
MsgBox, % count
return 

;q查找程序名尝试激活窗口
1::
WinActivate ,ahk_exe DecryptDICOMTools.exe
return
;我尝试通过pid激活窗口
2::
WinShow, ahk_pid 3040
WinActivate ,ahk_pid 3040
return

; 5::
; WinShow, ahk_pid 12308
; WinActivate ,ahk_pid 12308
; return

6::
Sleep, 500
WinShow, ahk_pid 3040
WinActivate ,ahk_pid 3040
sleep 200
Send ,5
SendRaw, 5

Sleep, 500
WinShow, ahk_pid 8824
WinActivate ,ahk_pid 8824
WinWait,ahk_pid 8824

Sleep, 500
WinShow, ahk_pid 3040
WinActivate ,ahk_pid 3040

sleep 500
WinActivate ,ahk_pid 21372
SendRaw,P
; send ,1
return
;激活后无法替换
3::
WinActivate  , ahk_pid %tpid%
return
4::
WinActivateBottom, ahk_exe %texe%
return
