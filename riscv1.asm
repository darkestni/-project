



.text
.globl _start

_start:
    # 读取 SWITCH 输入
    
    lui   t0, 0xFFFFF
    addi  t0, t0, 0x010       # t0 = 0xFFFFF010
    lw    t1, 0(t0)           # t1 = sw[10:0]

    # 提取 case（x3），a（x1），b（x2）
    srli  x3, t1, 8
    andi  x3, x3, 0x7         # x3 = sw[10:8]

    andi  x1, t1, 0xF         # a = sw[3:0]
    slli  x1, x1, 28
    srai  x1, x1, 28          # 符号扩展

    srli  t2, t1, 4
    andi  x2, t2, 0xF         # b = sw[7:4]
    slli  x2, x2, 28
    srai  x2, x2, 28          # 符号扩展

    # LED 地址 → t6
    lui   t6, 0xFFFFF
    addi  t6, t6, 0x000       # t6 = 0xFFFFF000
    
    
    
    #  设置确认按钮
    li   x8,  2048   #  sw11
    
    
    # 等待用户按下确认按钮
wait_confirm:
  sw   x0, 0(t0)
  lw   t1, 0(t0)
  and x9,  t1,  x8
  beq x9,x8, case_dispatch
  j wait_confirm
  
          
    


    # 跳转到对应 case
    
    case_dispatch:
    
    beq   x3, x0, case0
    li    x5, 1
    beq   x3, x5, case1
    li    x5, 2
    beq   x3, x5, case2
    li    x5, 3
    beq   x3, x5, case3
    li    x5, 4
    beq   x3, x5, case4
    li    x5, 5
    beq   x3, x5, case5
    li    x5, 6
    beq   x3, x5, case6
    li    x5, 7
    beq   x3, x5, case7
    j     end

# case0: 显示 sw[7:0]
case0:
    andi  x5, t1, 0xFF
    j     display_seg

# case1: 保存 a，lb 加载，符号扩展
case1:
    lui   x10, 0x00001
    addi  x10, x10, 0x010     # x10 = 0x00001010
    sb    x1, 0(x10)
    lb    x5, 0(x10)
    j     display_seg

# case2: 保存 a，lbu 加载，零扩展
case2:
    lui   x10, 0x00001
    addi  x10, x10, 0x010
    sb    x1, 0(x10)
    lbu   x5, 0(x10)
    j     display

# case3: 判断 a == b
case3:
    beq   x1, x2, led_on
    li    x5, 0
    j     display_led

# case4: a < b（有符号）
case4:
    blt   x1, x2, led_on
    li    x5, 0
    j     display_led

# case5: a < b（无符号）
case5:
    bltu  x1, x2, led_on
    li    x5, 0
    j     display_led

# case6: slt（signed）
case6:
    slt   x5, x1, x2
    lui   x10, 0x00001
    addi  x10, x10, 0x014
    sw    x5, 0(x10)
    lw    x5, 0(x10)
    j     display_seg

# case7: sltu（unsigned）
case7:
    sltu  x5, x1, x2
    lui   x10, 0x00001
    addi  x10, x10, 0x014
    sw    x5, 0(x10)
    lw    x5, 0(x10)
    j     display_seg

# LED 全亮（x5 = 0xFF）
led_on:
    li    x5, 0xFF
    j     display_led

# 显示 x5 到 LED（t6）
display_led:
    sw    x5, 0(t6)
    j     end

# 显示 x5 到 SEG（t7）
display_seg:
    lui   x7, 0xFFFFF
    addi  x7, x7, 0x020       # t7 = 0xFFFFF020
    sw    x5, 0(x7)
    j     end

# 程序结束，死循环
end:
    j    wait_confirm
