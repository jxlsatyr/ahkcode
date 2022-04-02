#Persistent
#SingleInstance, Force
#Include Decrypt.ahk

; 项目ID
ProjectId := "50f35598275011e8a53900163e02f99"

; 需要解压的文件路径
;ZipPath := "Z:\data\eimage\ebm_data\download\" ProjectId
ZipPath := "D:\" ProjectId "\download"
; 解压至文件路径
SrcPath := "D:\" ProjectId "\source"

; 7-Zip解压工具路径
7Zip := "D:\Program Files\7-Zip\7z.exe"

Loop Files, %ZipPath%\*.zip, F  ; 递归子文件
{
	; 1.解压
	DirName := StrReplace(A_LoopFileName, ".zip")
	FinalSrcPath := SrcPath "\" DirName
	FinalDecryptPath := DecryptPath "\" DirName
	RunWait , % 7Zip " x -y  -o" FinalSrcPath " " A_LoopFileFullPath 
	
	; 2.解密
	; 项目ID
	Obj := new Decrypt(ProjectId, DirName)
	obj.Start()
}
return