#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
counter := new SecondCounter
counter.Start()
Sleep 5000
counter.Stop()
Sleep 2000
1::
counter.show()
return

; An example class for counting the seconds...
class SecondCounter {
    __New() {
        this.interval := 1000
        this.count := 0
        ; Tick() has an implicit parameter "this" which is a reference to
        ; the object, so we need to create a function which encapsulates
        ; "this" and the method to call:
        this.timer := ObjBindMethod(this, "Tick")
    }
    Start() {
        ; Known limitation: SetTimer requires a plain variable reference.
        timer := this.timer
        SetTimer % timer, % this.interval
        ToolTip % "Counter started"
    }
    Stop() {
        ; To turn off the timer, we must pass the same object as before:
        timer := this.timer
        SetTimer % timer, Off
        ToolTip % "Counter stopped at " this.count
    }
    ; In this example, the timer calls this method:
    Tick() {
        ToolTip % ++this.count
    }
    show(){
        MsgBox, % this.count
    }
}