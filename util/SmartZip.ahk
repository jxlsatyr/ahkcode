#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
; SmartZip("C:\Program Files\AutoHotkey", "test.zip")   ; 将整个文件夹打包成ZIP文件
; SmartZip("*.ahk", "scripts.zip")   ; 打包工作目录下的ahk脚本
; SmartZip("*.zip", "package.zip")   ; 将所有ZIP文件打包成一个
; SmartZip("*.zip", "dir2")   ; 将所有ZIP文件解压至dir2
; SmartZip("*.zip", "dir2", 4|16)   ; 将所有ZIP文件解压至dir2，并覆盖和不提示
; SmartZip("*.zip", "")   ; 将所有ZIP文件解压缩到工作目录下
; return
/*
SmartZip()
   Smart ZIP/UnZIP files
参数:
   s, o 压缩时，s是源文件的目录或文件名，o是生成的ZIP文件名。 解压时，它们的情况正好相反。
   t      CopyHere方法使用的选项。关于可用的值，请参考: https://docs.microsoft.com/zh-cn/windows/win32/shell/folder-copyhere
(4) 不显示进度对话框。
(8) 如果具有目标名称的文件已存在，则为在移动、复制或重命名操作中使用新名称操作的文件。
(16) 对于显示的任何对话框，均为 "全部为"。
(64) 如果可能，请保留撤消信息。
(128) 只有在指定了通配符文件名时，才对文件 * () * 文件。
(256) 显示进度对话框，但不显示文件名。
(512) 如果操作需要创建一个新目录，请不要确认是否创建了一个新目录。
(1024) 如果发生错误，则不显示用户界面。
(2048) 版本 4.71。 不要复制文件的安全属性。
(4096) 仅在本地目录中操作。 不要以递归方式对子目录进行操作。
(8192) 版本 5.0。 不要将连接的文件作为组复制。 仅复制指定的文件。
*/
SmartZip(s, o, t = 4) {
	IfNotExist, %s%
		return, -1        ; 来源是不存在的。可能有拼写错误。
	oShell := ComObjCreate("Shell.Application")
	if (SubStr(o, -3) = ".zip") {	; Zip
		IfNotExist, %o%        ; 如果对象ZIP文件不存在，则创建该文件。
			CreateZip(o)
		
		Loop, %o%, 1
			sObjectLongName=%A_LoopFileLongPath%
		oObject := oShell.NameSpace(sObjectLongName)
		
		Loop, %s%, 1
		{
			if sObjectLongName = A_LoopFileLongPath
				continue
			oObject.CopyHere(A_LoopFileLongPath, t)
			SplitPath, A_LoopFileLongPath, OutFileName
			Loop
			{
				oObject := "", oObject := oShell.NameSpace(sObjectLongName)	; 这并不影响上面的副本。
				if oObject.ParseName(OutFileName)
					break
			}
		}
	} else if InStr(FileExist(o), "D") or (!FileExist(o) and (SubStr(s, -3) = ".zip")) {	; Unzip
		if !o
			o=%A_ScriptDir%        ; 如果对象为空，则使用工作目录代替。
		else IfNotExist, %o%
			FileCreateDir, %o%
		
		Loop, %o%, 1
			sObjectLongName=%A_LoopFileLongPath%
		
		oObject := oShell.NameSpace(sObjectLongName)
		
		Loop, %s%, 1
			oSource := oShell.NameSpace(A_LoopFileLongPath), oObject.CopyHere(oSource.Items, t)
	}
}
CreateZip(n) {	; 创建空的Zip文件
	ZIPHeader1 := "PK" . Chr(5) . Chr(6), VarSetCapacity(ZIPHeader2, 18, 0), ZIPFile := FileOpen(n, "w"), ZIPFile.Write(ZIPHeader1), ZIPFile.RawWrite(ZIPHeader2, 18), ZIPFile.close()
}