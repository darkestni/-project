.data
data_a:         .word 0
data_result:    .word 0

    .text
    .globl _start

_start:
                                   
                                 
    li x31, 0xFFFFF000      # 初始化 led 的 基地址

    
    li x1, 0x12             # 输入a
    li x2, 0x34             # 输入b
    li x3, 6                #   选择case的编号

    
    beq x3, x0, case0
    li x5, 1
    beq x3, x5, case1
    li x5, 2
    beq x3, x5, case2
    li x5, 3
    beq x3, x5, case3
    li x5, 4
    beq x3, x5, case4
    li x5, 5
    beq x3, x5, case5
    li x5, 6
    beq x3, x5, case6
    li x5, 7
    beq x3, x5, case7
    j end

case0:
    sw x1, 0(x31)
    j end

case1:
    la x10, data_a
    sb x1, 0(x10)
    lb x5, 0(x10)
    sw x5, 0(x31)
    j end

case2:
    la x10, data_a
    sb x1, 0(x10)
    lbu x5, 0(x10)
    sw x5, 0(x31)
    j end

case3:
    beq x1, x2, led_on
    sw x0, 0(x31)
    j end

case4:
    blt x1, x2, led_on
    sw x0, 0(x31)
    j end

case5:
    bltu x1, x2, led_on
    sw x0, 0(x31)
    j end
    
case6:
  slt x5,x1, x2
  la x10 data_result 
  sw x5,0(x10)
  lw x5, 0(x10)
  sw  x5, 0(x31)
  
  
  j end
  
  case7:
  sltu x5, x1, x2
   la x10, data_result
    sw x5, 0(x10)
    lw x5, 0(x10)
    sw x5, 0(x31)
    j end
    
    
    led_on:
    li x5, 0xFF
    sw x5, 0(x31)
    
    
    j end
    
    
    end:
    j end
    
    
    
    
    

    
    
    
