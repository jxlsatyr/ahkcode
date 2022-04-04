#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
;;防止自动监听操作页面时 输入命令串窗口 所以对操作上锁 排队处理


Class Oplock{
    lock:=""
    cur
    __New(){
    }
    lock(cur){
        while(this.lock){
            Sleep, 100
        }
        this.cur=cur
        this.lock:=1

    }
    unlock(cur){
        If (this.cur=cur){
            this.lock:=""
            this.cur:=""
        }
    }    

}