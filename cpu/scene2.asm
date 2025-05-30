.data

#input_addr:  .word 0xFFFFF010    # 开关输入地址
#led_addr:    .word 0xFFFFF000    # LED输出地址
#seg_addr:    .word 0xFFFFF020    # 数码管地址
#poly:        .word 0x3           # CRC-4多项式X^4 + X + 1

#float1:      .word 0x100100C0            # 存储第一个浮点数  如何储存12位浮点数?
#float2:      .word 0x100100C4             # 存储第二个浮点数

.text
.globl main

main:
    # 读取用例编号(开关高3位)
    #addi t0,x0, 0xFFFFFA10
    lui t0,0xFFFFF
    addi t0,t0,0x010
    lui  s0,0x10010
    addi s0,s0,0x0C0
    lui  s1,0x10010
    addi s1,s1,0x0C4
wait_confirm:

    lw   a0, 0(t0)
    srli a0, a0, 8             # 提取高3位作为用例编号(sw[10：8])
    srli a1, a0, 3   #确定键
    andi a0, a0, 0x7
    andi a1, a1, 0x1
    beqz a1,wait_confirm
    j case_jump
    
case_jump:
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
    li   t1, 5
    beq  a0, t1, case5          # 用例101
    li   t1, 6
    beq  a0, t1, case6          # 用例110
    li   t1, 7
    beq  a0, t1, case7          # 用例111

    j    main                   # 其他编号返回主循环

# 用例0: 8位倒序输出
case0:
    #lw   t0, input_addr
    lw   t1, 0(t0)   
    andi t1, t1, 0x00FF           
    li   t2, 0                  
    li   t3, 8                  # 循环计数器
reverse_loop:
    slli t2, t2, 1
    andi t4, t1, 1
    or   t2, t2, t4
    srli t1, t1, 1
    addi t3, t3, -1
    bnez t3, reverse_loop
    #lw   t0, led_addr
    sw   t2, -16(t0)              # 输出到LED
    j    main

# 用例1: 二进制回文判断

case1:
    #lw   t0, input_addr
    lw   t1, 0(t0)
    andi t1, t1, 0x00FF
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
    sw   t2, -16(t0)              # 输出结果(LED0)
    j    main

# 用例2: 浮点数输入与显示   未解决

case2: 
        
     # 读取输入（8位有效，低4位补0）
    #lw   t0, input_addr
    lw   a0, 0(t0)            # 读取32位输入
    srli a2,a0,12
    andi a2, a2, 1
    andi a0, a0, 0x00FF       # 取低8位
    slli a0, a0, 4            # 左移4位组成12位数据（高8位输入+低4位0）


    beqz a2, memory1
    j memory2
memory1:
    sw  a0, (s0)
    j cal
memory2:
    sw a0,  (s1)

cal:
    # 转换为十进制整数显示
    # 解析12位浮点格式：符号位[11], 指数[10:8], 尾数[7:4]
    srli t2, a0, 11           # 符号位
    andi t3, a0, 0x0700       # 指数
    srli t3, t3, 8
    andi t4, a0, 0x00F0       # 尾数
    srli t4, t4, 4

    # 计算实际值：(1 + fraction/16) * 2^(exponent-3)
    addi t5, zero, 1          # 隐含的1
    slli t5, t5, 4            # 1 << 4 = 16
    add  t5, t5, t4           # 1 + fraction/16 (整数形式)
    addi t3, t3, -3           # exponent bias
    sll  t5, t5, t3           # 乘以2^exp
    srli t5, t5, 4
    # 处理符号位
    beqz t2, positive
    neg  t5, t5
positive:
    # 显示十进制到数码管
    #lw   t0, seg_addr
    sw   t5, 16(t0)
    j    main

case3:
    lw t1, 0(s0)
    mv a0,t1
    jal float_to_int
    mv t1,a0
    
    lw t2, 0(s1)
    mv a0,t2
    jal float_to_int
    mv t2,a0
    
    add t3,t2,t1
    
    sw t3,16(t0)
    j main


# 用例4: CRC-4校验码生成
case4:
    lw a1,0(t0)
    andi a1,a1,0x0f
    slli t2,a1,4
    slli a2,a1,4
    addi a3,zero,0x13
    slli a3,a3,3
    addi a4,zero,4

crc_loop:
    srli a5, a2, 7          # 取出最高位（左移后第31位）
    andi a5,a5,1
    beqz a5, skip_xor        # 若最高位为0，跳过异或
    xor a2, a2, a3           # 异或生成多项式

skip_xor:
    slli a2, a2, 1           # 左移1位，处理下一位
    addi a4, a4, -1          # 循环计数器减1
    bnez a4, crc_loop        # 继续循环直到a4=0

# 提取余数（校验码）并拼接
    srli a6, a2, 4          # 提取高4位余数（校验码）
    or t1, t2, a6            # 拼接：a1 = data | crc

    sw t1, -16(t0)             # 将8位结果写入LED寄存器

    j    main
    
case5:
    li a0,1
    lw a1,0(t0)
    andi a1,a1,0xff
    andi t2,a1,0xf0
    srli a2,a1,4
    slli a2,a2,4
    addi a3,zero,0x13
    slli a3,a3,3
    addi a4,zero,4

crc_loop2:
    srli a5, a2, 7          # 取出最高位（左移后第31位）
    andi a5,a5,1
    beqz a5, skip_xor2        # 若最高位为0，跳过异或
    xor a2, a2, a3           # 异或生成多项式

skip_xor2:
    slli a2, a2, 1           # 左移1位，处理下一位
    addi a4, a4, -1          # 循环计数器减1
    bnez a4, crc_loop2        # 继续循环直到a4=0

# 提取余数（校验码）并拼接
    srli a6, a2, 4          # 提取高4位余数（校验码）
    or t1, t2, a6            # 拼接：a1 = data | crc

    beq a1,t1,out
    j wrong
wrong:
    li a0,0
out:        
    sw a0,-16(t0)
    j    main
# 用例6: lui指令测试

case6:
    lui  a0, 0x12345            # 加载高位立即数
    addi a0, a0, 0x678          # 组合低位

    sw   a0, 16(t0)
    j    main
case7:
    lui t1,0x12345
    addi t1,t1,0x678
    
    jal func
    
    sw t1,16(t0)
    j main
func:
    addi t1,t1,0x1
    jr ra
float_to_int:
      # 输入a0=12位浮点，输出a0=整数
    srli t6, a0, 11           # 符号位
    andi t3, a0, 0x0700
    srli t3, t3, 8            # 指数
    andi t4, a0, 0x00F0
    srli t4, t4, 4            # 尾数
    
    addi t5, zero, 1
    slli t5, t5, 4
    add  t5, t5, t4
    addi t3, t3, -3
    sll  t5, t5, t3
    srli t5, t5, 4
    beqz t6, pos
    neg  t5, t5
pos:
    mv   a0, t5
    jr ra
