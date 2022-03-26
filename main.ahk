#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
#Include, %A_ScriptDir%/model/Model.ahk
;初始化配置变量
sqlInterval:=10000

SetTimer, obj.check ,on, sqlInterval
FunctionReference := Func(FunctionName)

callback(obj){
     for k, v in obj
        s .= k "=" v "`n"
    MsgBox % s
}
