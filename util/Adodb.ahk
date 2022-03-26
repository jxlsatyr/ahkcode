#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%


class Adodb
{
    static conn
 
    __New() ;新建
    {
    this.conn:= ComObjCreate("ADODB.connection") ;初始化COM
    }
 
    open(connect_str) ;打开连接
    {
        try
            this.conn.Open(connect_str)
        catch e
            return e.Message
    }
 
    close() ;关闭连接
    {
        this.conn.Close()
    }
 
    sqlQuery(sql)
    {
        t := []
        query := this.conn.Execute(sql)
        try
        {
            fetchedArray := query.GetRows() ;取出数据（二维数组）
            colSize := fetchedArray.MaxIndex(1) + 1 ;列最大值 tips：从0开始 所以要+1
            rowSize := fetchedArray.MaxIndex(2) + 1 ;行最大值 tips：从0开始 所以要+1
            loop, % rowSize
            {
                MsgBox %  fetchedArray.fileds.1
                i := (y := A_index) - 1
                t[y] := []
                loop, % colSize
                {
                    j := (x := A_index) - 1
                    ; MsgBox % fetchedArray[j,i]
                    t[y][x] := fetchedArray[j,i] ;取出二维数组内值
                }
            }
        }
        query.Close()
        this.close()
        return t
    }
}

; a := new Adodb
; a.open("DSN=mysql.test;") ;到DSN里面配置了用户名密码则UID PWD不用配置。
; ret := a.sqlQuery("select id,name from t_mdm_form order by create_time desc limit 1")
; ; a.Close()
; MsgBox % ret.1.1
 