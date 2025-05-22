.data
input_addr:   .word 0xFFFFF010
led_addr:     .word 0xFFFFF000
seg_addr:     .word 0xFFFFF020

data_a:       .space 4
data_result:  .word 0

.text
.globl _start

_start:
    # IO 开关输入 
    lui   t0, 0x00001
    addi  t0, t0, 0x000          # t0 = 0x00001000
    lw    t0, 0(t0)              # t0 = 0xFFFFF010
    lw    t1, 0(t0)              # t1 = sw[10:0]

    # case、a、b 
    srli  x3, t1, 8
    andi  x3, x3, 0x7            # x3 = case

    andi  x1, t1, 0xF
    slli  x1, x1, 28
    srai  x1, x1, 28            # a = sw[3:0] (sign extend)

    srli  t2, t1, 4
    andi  x2, t2, 0xF
    slli  x2, x2, 28
    srai  x2, x2, 28            # b = sw[7:4] (sign extend)

    li    x31, 0xFFFFF000       # LED地址

    # 跳转 
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
    j     display

# case1: 保存 a，lb 加载，符号扩展输出 
case1:
    lui   x10, 0x00001
    addi  x10, x10, 0x010       # x10 = 0x00001010
    sb    x1, 0(x10)
    lb    x5, 0(x10)
    j     display

#  case2: 保存 a，lbu 加载，零扩展输出 
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
    j     display

#  case4: a < b (signed) 
case4:
    blt   x1, x2, led_on
    li    x5, 0
    j     display

# case5: a < b (unsigned) 
case5:
    bltu  x1, x2, led_on
    li    x5, 0
    j     display

#  case6: slt (signed) 
case6:
    slt   x5, x1, x2
    lui   x10, 0x00001
    addi  x10, x10, 0x014
    sw    x5, 0(x10)
    lw    x5, 0(x10)
    j     display

# case7: sltu (unsigned) 
case7:
    sltu  x5, x1, x2
    lui   x10, 0x00001
    addi  x10, x10, 0x014
    sw    x5, 0(x10)
    lw    x5, 0(x10)
    j     display

# LED 点亮时使用 x5 = 0xFF 
led_on:
    li    x5, 0xFF
    j     display

# 显示结果到 LED 和数码管 
display:
    sw    x5, 0(x31)            # LED 显示
    li    t6, 0xFFFFF020
    sw    x5, 0(t6)             # 数码管显示
    j     end

# 死循环结束 
end:
    j     end
