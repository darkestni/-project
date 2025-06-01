.data

initial:  .word 0


.text

.globl _start

_start:
    # 初始化 IO 基地址
    lui    t0, 0xFFFFF         # t0 = 0xFFFFF000
    addi   t0, t0, 0x010       # t0 = SW 基址 0xFFFFF010
    lui    t6, 0xFFFFF         # t6 = LED 基址 0xFFFFF000
    lui    t3, 0xFFFFF         # t3 = 数码管基址
    addi   t3, t3, 0x020       # t3 = 0xFFFFF020
    li     t4, 0x800           # t4 = 0x800 (bit11)

main_loop:
    # 等待 sw[11] 被拨上
    lw     t1, 0(t0)           # 读取 switch 输入
    and    t2, t1, t4          # 检查 bit11
    beq    t2, x0, main_loop   # 如果 sw[11] 没有拨上，继续等待

    # 继续执行任务
    # 提取 case = sw[10:8]
    srli   s0, t1, 8
    andi   s0, s0, 0x7         # s0 = case 号 (0~7)

case_dispatch:
    li     s1, 0
    beq    s0, s1, case0
    li     s1, 1
    beq    s0, s1, case1
    li     s1, 2
    beq    s0, s1, case2
    li     s1, 3
    beq    s0, s1, case3
    li     s1, 4
    beq    s0, s1, case4
    li     s1, 5
    beq    s0, s1, case5
    li     s1, 6
    beq    s0, s1, case6
    li     s1, 7
    beq    s0, s1, case7
    j      main_loop

# case0: 直接显示 sw[7:0] 到 LED
case0:
    andi   a0, t1, 0xFF
    j      display_led

# case1: 保存 a，lb 加载，符号扩展
case1:
    andi   a0, t1, 0xFF
    lui    a1, 0x00001
    addi   a1, a1, 0x010
    sb     a0, 0(a1)
    lb     a0, 0(a1)
    j      display_seg

# case2: 保存 b，lbu 加载，零扩展
case2:
    srli   s2, t1, 4
    andi   s2, s2, 0xF
    lui    a1, 0x00001
    addi   a1, a1, 0x010
    sb     s2, 0(a1)
    lbu    a0, 0(a1)
    j      display_seg

# case3: 比较 a == b（有符号）
case3:
    andi   s3, t1, 0xF
    slli   s3, s3, 28
    srai   s3, s3, 28
    srli   s2, t1, 4
    andi   s4, s2, 0xF
    slli   s4, s4, 28
    srai   s4, s4, 28
    beq    s3, s4, led_on
    li     a0, 0
    j      display_led

# case4: 比较 a < b（有符号）
case4:
    andi   s3, t1, 0xF
    slli   s3, s3, 28
    srai   s3, s3, 28
    srli   s2, t1, 4
    andi   s4, s2, 0xF
    slli   s4, s4, 28
    srai   s4, s4, 28
    blt    s3, s4, led_on
    li     a0, 0
    j      display_led

# case5: 比较 a < b（无符号）
case5:
    andi   s3, t1, 0xF
    srli   s2, t1, 4
    andi   s4, s2, 0xF
    bltu   s3, s4, led_on
    li     a0, 0
    j      display_led

# case6: slt 有符号
case6:
    andi   s3, t1, 0xF
    slli   s3, s3, 28
    srai   s3, s3, 28
    srli   s2, t1, 4
    andi   s4, s2, 0xF
    slli   s4, s4, 28
    srai   s4, s4, 28
    slt    a0, s3, s4
    j      display_seg

# case7: sltu 无符号
case7:
    andi   s3, t1, 0xF
    srli   s2, t1, 4
    andi   s4, s2, 0xF
    sltu   a0, s3, s4
    j      display_seg

# LED 全亮
led_on:
    li     a0, 0xFF
    j      display_led

# 输出到 LED
display_led:
    sw     a0, 0(t6)
    j      main_loop

# 输出到数码管
display_seg:
    sw     a0, 0(t3)
    j      main_loop
