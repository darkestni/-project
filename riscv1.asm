.data
input_addr:   .word 0xFFFFF010        # 开关输入基地址（指向真实 IO）
led_addr:     .word 0xFFFFF000        # LED输出地址
seg_addr:     .word 0xFFFFF020        # 数码管地址

data_a:       .space 4                # 存放1字节数据
data_result:  .word 0                 # 存放slt/sltu结果

.text
.globl _start

_start:
    
    la   t0, input_addr
    lw   t0, 0(t0)                    # t0 = 开关输入地址
    lw   t1, 0(t0)                    # t1 = sw[10:0] 当前拨码值

    # 提取用例编号（sw[10:8]）
    srli x3, t1, 8
    andi x3, x3, 0x7                  # x3 = case号（0~7）

    # 提取 a = sw[3:0]，符号扩展
    andi x1, t1, 0xF
    slli x1, x1, 28
    srai x1, x1, 28

    # 提取 b = sw[7:4]，符号扩展
    srli t2, t1, 4
    andi x2, t2, 0xF
    slli x2, x2, 28
    srai x2, x2, 28

    # 设置 LED 输出地址
    li   x31, 0xFFFFF000

    # 跳转分支
    beq  x3, x0, case0
    li   x5, 1
    beq  x3, x5, case1
    li   x5, 2
    beq  x3, x5, case2
    li   x5, 3
    beq  x3, x5, case3
    li   x5, 4
    beq  x3, x5, case4
    li   x5, 5
    beq  x3, x5, case5
    li   x5, 6
    beq  x3, x5, case6
    li   x5, 7
    beq  x3, x5, case7
    j    end

# 用例 0：直接显示 sw[7:0]
case0:
    andi x5, t1, 0xFF       # 提取 sw[7:0]
    sw   x5, 0(x31)
    j    end

# 用例 1：保存 a，lb 加载，输出
case1:
    la   x10, data_a
    sb   x1, 0(x10)
    lb   x5, 0(x10)
    sw   x5, 0(x31)
    j    end

# 用例 2：保存 a，lbu 加载，输出
case2:
    la   x10, data_a
    sb   x1, 0(x10)
    lbu  x5, 0(x10)
    sw   x5, 0(x31)
    j    end

# 用例 3：beq 判断
case3:
    beq  x1, x2, led_on
    sw   x0, 0(x31)
    j    end

# 用例 4：blt 有符号小于
case4:
    blt  x1, x2, led_on
    sw   x0, 0(x31)
    j    end

# 用例 5：bltu 无符号小于
case5:
    bltu x1, x2, led_on
    sw   x0, 0(x31)
    j    end

# 用例 6：slt 比较
case6:
    slt  x5, x1, x2
    la   x10, data_result
    sw   x5, 0(x10)
    lw   x5, 0(x10)
    sw   x5, 0(x31)
    j    end

# 用例 7：sltu 比较
case7:
    sltu x5, x1, x2
    la   x10, data_result
    sw   x5, 0(x10)
    lw   x5, 0(x10)
    sw   x5, 0(x31)
    j    end

# 通用 LED 点亮
led_on:
    li   x5, 0xFF
    sw   x5, 0(x31)
    j    end

# 死循环等待
end:
    j end
