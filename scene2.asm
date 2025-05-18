.data

input_addr:  .word 0xFFFFF010    # 开关输入地址
led_addr:    .word 0xFFFFF000    # LED输出地址
seg_addr:    .word 0xFFFFF020    # 数码管地址
poly:        .word 0x3           # CRC-4多项式X^4 + X + 1

float1:      .word 0             # 存储第一个浮点数
float2:      .word 0             # 存储第二个浮点数

.text
.globl main

main:
    # 读取用例编号(开关高3位)
    lw   t0, input_addr
    lw   a0, 0(t0)
    srli a0, a0, 5              # 提取高3位作为用例编号(sw[7:5])
    andi a0, a0, 0x7

    # 用例跳转表
    li   t1, 0
    beq  a0, t1, case0          # 用例000: 倒序
    li   t1, 1
    beq  a0, t1, case1          # 用例001: 回文判断
    li   t1, 2
    beq  a0, t1, case2          # 用例010: 浮点数输入1
    li   t1, 3
    beq  a0, t1, case3          # 用例011: 浮点数加法
    li   t1, 4
    beq  a0, t1, case4          # 用例100: CRC生成
    li   t1, 6
    beq  a0, t1, case6          # 用例110: lui测试
    j    main                   # 其他编号返回主循环

# 用例0: 8位倒序输出
case0:
    lw   t0, input_addr
    lb   t1, 0(t0)              
    li   t2, 0                  
    li   t3, 8                  # 循环计数器
reverse_loop:
    slli t2, t2, 1
    andi t4, t1, 1
    or   t2, t2, t4
    srli t1, t1, 1
    addi t3, t3, -1
    bnez t3, reverse_loop
    lw   t0, led_addr
    sw   t2, 0(t0)              # 输出到LED
    j    main

# 用例1: 二进制回文判断

case1:
    lw   t0, input_addr
    lb   t1, 0(t0)
    li   t2, 1                  # 默认回文标志
    li   t3, 7                  # 高位索引
    li   t4, 0                  # 低位索引
palindrome_check:
    srl  t5, t1, t3
    srl  t6, t1, t4
    andi t5, t5, 1
    andi t6, t6, 1
    bne  t5, t6, not_pali
    addi t3, t3, -1
    addi t4, t4, 1
    blt  t4, t3, palindrome_check
    j    output_pali
not_pali:
    li   t2, 0
output_pali:
    sw   t2, 0(t0)              # 输出结果(LED0)
    j    main

# 用例2: 浮点数输入与显示

case2: #如何输入12位
    lw   t0, input_addr
    lh   a0, 0(t0)              # 读取12位浮点数
    call parse_float
    sw   a0, float1, t5
    call display_decimal
    j    main

# 用例4: CRC-4校验码生成

case4:
    lw   t0, input_addr
    lb   t1, 0(t0)              # 读取4位输入
    li   t2, 0                  # CRC结果
    li   t3, 4                  # 循环次数
    lw   t5, poly
crc_loop:
    slli t2, t2, 1
    xor  t4, t1, t2
    srli t4, t4, 3
    andi t4, t4, 1
    beqz t4, no_xor
    xor  t2, t2, t5
no_xor:
    srli t1, t1, 1
    addi t3, t3, -1
    bnez t3, crc_loop
    slli t1, t1, 4              # 拼接原数据与CRC
    or   t1, t1, t2
    sw   t1, led_addr, t5       # 输出到LED
    j    main


# 用例6: lui指令测试

case6:
    lui  a0, 0x12345            # 加载高位立即数
    addi a0, a0, 0x678          # 组合低位
    sw   a0, seg_addr, t0       # 数码管显示
    j    main


# 浮点解析函数（符号位+3位指数+4位尾数）

parse_float:
    srai a1, a0, 11            # 符号位
    andi a2, a0, 0x7C0         # 指数
    srli a2, a2, 6
    andi a3, a0, 0x3F          # 尾数
    # 转换为整数（示例：忽略指数）
    mv   a0, a3
    ret


# 十进制显示函数

display_decimal:
    lw   t0, seg_addr
    addi a0, a0, 48            # ASCII转换
    sw   a0, 0(t0)
    ret


case3:                         # 浮点加法（需自行实现）
case5:                         # CRC校验（需自行实现）
    j    main