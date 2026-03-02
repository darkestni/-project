# VHDL/Verilog 代码风格指南

本项目遵循 FPGA 开发的代码风格规范。

## 编码规范

### 1. 命名规范

- **模块名**: 使用大写字母 + 下划线
  ```verilog
  module CPU_TOP (
      input clk,
      input rst
  );
  ```

- **信号名**: 使用小写字母 + 下划线
  ```vhdl
  signal data_bus : std_logic_vector(31 downto 0);
  signal valid_flag : std_logic;
  ```

- **常量**: 使用大写字母 + 下划线
  ```vhdl
  constant DATA_WIDTH : integer := 32;
  ```

### 2. 代码格式

- **缩进**: 使用 2-4 个空格
- **关键字**: 使用大写（VHDL）或小写（Verilog）
- **空行**: 逻辑段落之间空 1 行

### 3. 注释规范

```verilog
// 单行注释

/*
 * 多行注释
 * 说明模块功能
 */
```

```vhdl
-- 单行注释

-- 多行注释
-- 说明模块功能
```

### 4. 模块结构

```verilog
module module_name (
    // 时钟和复位
    input clk,
    input rst_n,
    // 输入信号
    input data_in,
    // 输出信号
    output reg data_out
);
    // 内部信号定义
    wire internal_signal;

    // 逻辑实现
    always @(posedge clk or negedge rst_n) begin
        // ...
    end
endmodule
```

## 工具配置

### Vivado 设置

在项目设置中启用代码风格检查。

## 设计原则

1. **同步设计**: 尽量使用时序逻辑
2. **复位设计**: 使用异步复位，同步释放
3. **时序约束**: 添加适当的时序约束
4. **可综合**: 确保代码可综合
