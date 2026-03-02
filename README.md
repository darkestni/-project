# -project

CPU 设计与实现项目

## 项目简介

本项目是一个基于 VHDL 的 CPU 设计与实现，包含完整的 CPU 架构设计、指令集实现和测试验证。

## 目录结构

```
.
├── cpu/                    # CPU 核心模块
├── project_6.srcs/         # Vivado 工程文件
├── *.v                     # Verilog/VHDL 源码
├── *.coe                   # 存储器初始化文件
├── *.asm                   # 汇编测试程序
└── *.png                   # 设计文档截图
```

## 主要模块

- **CPU.v** - CPU 顶层模块
- **cpu/** - CPU 子模块（ALU、寄存器堆、控制器等）
- **project_6.srcs/** - Vivado 工程源文件

## 测试文件

- `basic test1.asm` - 基础测试汇编程序
- `riscv1.asm` - RISC-V 指令测试
- `scene2.asm` - 场景测试 2

## 工具要求

- Xilinx Vivado
- VHDL/Verilog 仿真器

## 相关文档

- `中期答辩.md` - 项目中期报告
- `CS202-Project-2025s-in-Chinese.pdf` - 项目指导文档
