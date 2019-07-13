datas segment
    buff      db 6, ?, 6 dup(?)    
    Factorial dw 1, 999 dup(0)         ;阶乘，初值为1
    TempF     dw 1000 dup(0)            ;临时阶乘  
    Divisor   dw 1000 dup(0)            ;除数
    Quotient  dw 1000 dup(0)            ;商
    Result    db 1000 dup(0)           ;阶乘结果的非压缩BCD码形式
    N    dw 0                        ;N的2进制形式     
    i    dw 1                        ;2进制Factorial的字数  
    j    dw 0                        ;十进制阶乘的位数
    a    dw 1, 10, 100, 1000, 10000  ;Buff中字符转为N时用到 
    b    dw ?     
    msg1 db  "Please input N: $"
    msg2 db 0ah, 0dh, "Press any key to exit...$" 
    msg3 db 0ah, 0dh, "N!=$"    
datas ends

stacks segment
	;
stacks ends

codes segment
    assume cs: codes, ds: datas, ss: stacks, es: datas
start:
               mov ax, datas
               mov ds, ax
               mov es, ax
               
               Main:
               
               call Input    ;输入N
               call Factor   ;计算N!
               call Convert  ;将2进制Factorial转为非压缩BCD码Result
               call Output
               jmp  Final
               
;------------------------------------------------------------------------------
;输入字符型N，转为2进制
               
               Input:            
    
               lea  dx, msg1
               mov  ah, 9
               int  21h
    
               lea  dx, buff
               mov  ah, 10
               int  21h            
                                   
               lea  di, a    ;将输入字符串转化为整数存入N
               mov  ch, 0
               mov  cl, buff+1
               mov  si, cx              
      L0:      mov  ah, 0
               mov  al, buff[si+1]
               sub  al, 30h
               dec  si
               mov  bx, [di]
               mul  bx
               add  N,  ax         
               add  di, 2
               loop L0 
               
               ret

;输入字符型N，转为2进制
;------------------------------------------------------------------------------               
;计算N!
               
               Factor:               
               
               mov  bx, 1
               mov  cx, N
      L1:      push cx
               lea  di, TempF
               lea  si, Factorial
               mov  cx, i
      L2:      mov  ax, [si]
               mov  [di], ax
               mov  ax, 0
               mov  [si], ax
               add  si, 2
               add  di, 2
               loop L2
                              
               lea  di, TempF
               lea  si, Factorial
               mov  cx, i               
      L3:      mov  ax, [di]
               mov  dx, 0
               mul  bx
               add  [si], ax
               adc  [si+2], dx
               add  si, 2
               add  di, 2
               loop L3
                     
               cmp  dx, 0
               jz   N1
               add  i, 1               
      N1:      inc  bx
               pop  cx
               loop L1
               
               ret
 
;计算N!             
;-----------------------------------------------------------------------------
;将2进制Factorial转为非压缩BCD码Result
                                     
               Convert:                                                      
               
               mov ax, i
               mov bx, 2
               mul bx
               sub ax, 2
               mov b, ax                              
            
       L11:    call setD       ;设置除数
               call div10           
               call Save
               call cmpQz      ;测试商是否为零
               cmp  ax, 0
               jz   N5  
               call movQF      ;将商移入Factorial做下一步除法               
               call clQ        ;商清零                             
               jmp  L11               
       N5:     
               
               ret
                              
       ;..........................................
      
               setD:
               
               lea di, Quotient
               mov cx, i
               mov ax, 0
       L10:    mov [di], ax
               add di, 2
               loop L10 
               mov ax, 0a000h
               mov [di-2], ax 
               
               ret
               
       ;..........................................
      
               Div10:
                              
               mov bx, 16
               mov ax, i
               mul bx
               sub ax, 3    
               mov  cx, ax              
       L7:     push cx
               call CmpFD
               jb   N2
               call SubFD
               stc                                
               jmp  N3               
       N2:     clc                                   
       N3:     call QSHL
               call DSHR
               pop cx
               loop L7 
               
               ret   
  
      ;..........................................  

               Save:  
                            
               lea si, Factorial
               lea di, Result
               mov ax, j
               add di, ax
               mov al, [si]
               mov [di], al
               lea di, j
               mov ax, 1
               add [di], ax
               
               ret
                      
       ;..........................................

               cmpQz:
               
               lea  si, Divisor
               mov  cx, i
       L15:    mov  ax, [si] 
               cmp  ax, 0
               jnz  N4
               add  si, 2
               loop L15
   
       N4:       ret
       
       ;..........................................
       
               movQF:

               lea di, Factorial
               lea si, Divisor
               mov cx, i
       L9:     mov ax, [si]
               mov [di], ax
               add si, 2
               add di, 2
               loop L9  
               
               ret
               
       ;...........................................
                      
               clQ:
               
               lea di, Divisor
               mov cx, i
               mov ax, 0
       L12:    mov [di], ax
               add di, 2
               loop L12 
               
               ret
                      
       ;.......................................... 
                                  
               CmpFD: 
                               
               lea  di, Quotient
               lea  si, Factorial
               add  di, b
               add  si, b
               mov  cx, i
               std
               repz cmpsw
               
               ret               
       
      ;..........................................    
               
               SubFD: 
                                                                
               lea  di, Factorial
               lea  si, Quotient              
               mov  cx, i
               clc
       L4:     mov  bx, [si]
               sbb  [di], bx
               inc  si
               inc  si
               inc  di
               inc  di
               loop L4
               
               ret
               
     ;..........................................
               
               QSHL:
               
               lea  si, Divisor                            
               mov  cx, i   
       L5:     rcl  word ptr[si], 1
               inc  si
               inc  si
               loop L5
               
               ret

      ;..........................................
               
               DSHR:
               
               lea  si, Quotient
               add  si, b
               mov  cx, i
               clc   
       L6:     rcr word ptr[si], 1
               dec si
               dec si             
               loop L6
               
               ret
                                                          
;将2进制Factorial转为非压缩BCD码Result             
;-----------------------------------------------------------------------------
;输出!
       
              Output: 
              
              lea dx, msg3
              mov ah, 9
              int 21h 
                                                           
              lea di, Result
              mov cx, j
              add di, cx
              sub di, 1  
              
       L14:   mov dl, [di]
              cmp dl, 0
              jnz L13
              dec di
              loop L14
              
       L13:   mov dl, [di]
              add dl, 30h
              mov ah, 2
              int 21h
              dec di
              loop L13
              
              ret

;输出N!                                                                   
;------------------------------------------------------------------------------
                              
               Final:
                                            
               lea dx, msg2
               mov ah, 9
               int 21h 
               
               mov ah, 1
               int 21h     
                  
               mov ah, 4ch
               int 21h
codes ends
    end start