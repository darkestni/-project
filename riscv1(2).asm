.text
    .globl _start

_start:
    # 初始化外设基址
    lui    t0, 0xFFFFF         # t0 = 0xFFFFF000
    addi   t0, t0, 0x010       # t0 = SW 基址 0xFFFFF010
    lui    t6, 0xFFFFF         # t6 = 0xFFFFF000
    # t6 已经是 LED 基址 0xFFFFF000，不需要再加
    lui    t3, 0xFFFFF         # t3 = 0xFFFFF000  
    addi   t3, t3, 0x020       # t3 = 七段显示基址 0xFFFFF020
    addi   t4, x0, 1           # t4 = 1
    slli   t4, t4, 11          # t4 = 0x800 (bit 11)

wait_confirm:
    lw     t1, 0(t0)           # 读取开关输入 sw[11:0]
    and    t2, t1, t4          # 检查 bit11
    beq    t2, t4, wait_release # 如果按下确认键，等待释放
    j      wait_confirm

wait_release:
    lw     t1, 0(t0)           # 再次读取
    and    t2, t1, t4          # 检查 bit11
    bne    t2, x0, wait_release # 如果还在按下，继续等待
    # 按钮已释放，继续执行

extract_case:
    # 提取 case = sw[10:8]
    srli   s0, t1, 8           # 使用 s0 保存移位后的值
    andi   s0, s0, 0x7         # s0 = case number

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
    j      end

# case0: 直接显示 sw[7:0] 到 LED
case0:
    andi   a0, t1, 0xFF         # a0 = sw[7:0]
    j      display_led

# case1: 保存 a，lb 加载，符号扩展
case1:
    andi   a0, t1, 0xFF         # a0 = sw[7:0]
    lui    a1, 0x00001
    addi   a1, a1, 0x010        # 存储地址 0x00001010
    sb     a0, 0(a1)            # 存储字节
    lb     a0, 0(a1)            # 符号扩展加载
    j      display_seg

# case2: 保存 b，lbu 加载，零扩展
case2:
    srli   s2, t1, 4
    andi   s2, s2, 0xF          # s2 = sw[7:4]
    lui    a1, 0x00001
    addi   a1, a1, 0x010
    sb     s2, 0(a1)            # 存储字节
    lbu    a0, 0(a1)            # 零扩展加载
    j      display_seg

# case3: 判断 a == b
case3:
    andi   s3, t1, 0xF          # a = sw[3:0]
    slli   s3, s3, 28
    srai   s3, s3, 28           # 符号扩展
    srli   s2, t1, 4
    andi   s4, s2, 0xF          # b = sw[7:4]
    slli   s4, s4, 28
    srai   s4, s4, 28           # 符号扩展
    beq    s3, s4, led_on
    li     a0, 0
    j      display_led

# case4: a < b（有符号）
case4:
    andi   s3, t1, 0xF
    slli   s3, s3, 28
    srai   s3, s3, 28           # 符号扩展
    srli   s2, t1, 4
    andi   s4, s2, 0xF
    slli   s4, s4, 28
    srai   s4, s4, 28           # 符号扩展
    blt    s3, s4, led_on
    li     a0, 0
    j      display_led

# case5: a < b（无符号）
case5:
    andi   s3, t1, 0xF          # a = sw[3:0]
    srli   s2, t1, 4
    andi   s4, s2, 0xF          # b = sw[7:4]
    bltu   s3, s4, led_on
    li     a0, 0
    j      display_led

# case6: slt（signed）
case6:
    andi   s3, t1, 0xF
    slli   s3, s3, 28
    srai   s3, s3, 28           # 符号扩展
    srli   s2, t1, 4
    andi   s4, s2, 0xF
    slli   s4, s4, 28
    srai   s4, s4, 28           # 符号扩展
    slt    a0, s3, s4
    j      display_seg

# case7: sltu（unsigned）
case7:
    andi   s3, t1, 0xF          # a = sw[3:0]
    srli   s2, t1, 4
    andi   s4, s2, 0xF          # b = sw[7:4]
    sltu   a0, s3, s4
    j      display_seg

# LED 全亮
led_on:
    li     a0, 0xFF
    j      display_led

# 显示到 LED
display_led:
    sw     a0, 0(t6)
    j      end

# 显示到七段显示器
display_seg:
    sw     a0, 0(t3)
    j      end

# 返回等待下次触发
end:
    j      wait_confirm