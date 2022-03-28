#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%

class Monitor{
    static queueCap:=5
    static objs
    static callback
    static interval:=10000
    __New(cap,callback){
        ;todo  param validator
        this.queueCap:=cap
        this.callback:=callback
        this.timer := ObjBindMethod(this, "CheckCallback")
        timer := this.timer
        SetTimer % timer, % this.interval
        ; SetTimer, check, 10000
    }
    ;增加监听
    addTracker(key,value){
        if(key=nil)
        if(this.objs.HasKey(key)){
            this.objs[key]:=value
        }
        if(this.objs.Count()>=this.queueCap){
        ;;todo 异常处理
        }else{
            ;队列里增加 key:value 对
            this.objs[key]:=value
        }
    }
    deleteTracker(key){
        if(this.objs[Key]){
            this.objs.Delete(key)
        }
    }
    CheckCallback(){
        if(this.objs.Count()=0){
            return
        }
        For key,checkObj in this.objs{
            this.callback.call(checkObj)
        }
    }
}

;;创建监听    将callback方法注册
obj:=new Monitor(5,Func("callback"))
; obj.Add("s",Object("red", 0xFF0000, "blue", 0x0000FF, "green", 0x00FF00))
;增加一个需要监听的对象
obj.addTracker("s",Object("red", 0xFF0000, "blue", 0x0000FF, "green", 0x00FF00))
; obj.Add("b",Object("red", 0xFF0000, "blue", 0x0000FF, "green", 0x00FF00))
obj.deleteTracker("s")
; obj.check();人肉触发全部check

callback(obj){
     for k, v in obj
        s .= k "=" v "`n"
    MsgBox % s
    ; Log(s)
}


1::
return 