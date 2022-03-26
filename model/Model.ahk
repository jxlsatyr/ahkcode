#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%

class Tracker{
    static queueCap:=5
    static objs
    static callback
    __New(cap,callback){
        ;todo  param validator
        this.queueCap:=cap
        this.objs.SetCapacity(1)
        this.callback:=callback
        ; SetTimer, check, 10000
    }
    ;增加监听
    Add(key,value){
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
    delete(key){
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

; colours := Object("red", 0xFF0000, "blue", 0x0000FF, "green", 0x00FF00)
; ; The above expression could be used directly in place of "colours" below:
; for k, v in colours
;     s .= k "=" v "`n"
; MsgBox % s

obj:=new Tracker(5,Func("callback"))
; obj.Add("s",Object("red", 0xFF0000, "blue", 0x0000FF, "green", 0x00FF00))
obj.Add("s",Object("red", 0xFF0000, "blue", 0x0000FF, "green", 0x00FF00))
; obj.Add("b",Object("red", 0xFF0000, "blue", 0x0000FF, "green", 0x00FF00))
obj.Delete("s")
; obj.check()

callback(obj){
     for k, v in obj
        s .= k "=" v "`n"
    MsgBox % s
    ; Log(s)
}
;SetTimer 只能绑定label 所以只能将属性外挂到label上
check:
    obj.CheckCallback()
return

1::
return 