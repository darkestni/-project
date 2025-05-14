module PipelineCPU (
    input clk,
    input reset,
    input  [15:0] switch_in,  // 拨码开关输入
    output [15:0] led_out     // LED输出
);
    localparam BUTTON_WIDTH = 3; 
    localparam DIP_WIDTH = 16; // 假设拨码开关宽度为16位
    localparam LED_WIDTH = 16; 

    wire branch;
    wire [31:0] target_pc_in_if;
    wire stall_if; //占位
    reg debugMode = 1'b1; 
    reg [31:0] testScenario = 32'd0; // 测试场景输入
    wire [31:0] instruction_to_ifid;
    wire [31:0] pc_current_to_ifid;
    wire [31:0] pc_plus_4_to_ifid;
    IFetch u_ifetch (
        .clk(clk),
        .reset(reset),
        .branch(branch),
        .target_pc_in_if(target_pc_in_if),
        .stall_if(stall_if),
        .debugMode(debugMode),
        .testScenario(testScenario),
        .instruction_to_ifid(instruction_to_ifid),
        .pc_current_to_ifid(pc_current_to_ifid),
        .pc_plus_4_to_ifid(pc_plus_4_to_ifid) 
    );


    wire ifid_enable_write;
    assign ifid_enable_write = 1'b1; // 占位
    wire ifid_flush_ifid;
    wire [31:0] instruction_to_id;
    wire [31:0] pc_current_to_id;
    wire [31:0] pc_plus_4_to_id;
    IFID_PipelineRegister u_ifid_reg (
        .clk(clk),
        .reset(reset),
        .enable_write(ifid_enable_write), // 这里假设总是允许写入
        .flush_ifid(ifid_flush_ifid),   // 假设没有冲刷信号
        .instruction_from_if(instruction_to_ifid),
        .pc_current_from_if(pc_current_to_ifid),
        .pc_plus_4_from_if(pc_plus_4_to_ifid),
        .instruction_to_id(instruction_to_id),
        .pc_current_to_id(pc_current_to_id),
        .pc_plus_4_to_id(pc_plus_4_to_id)
    );


    wire write_addr_from_wb;
    wire write_data_from_wb;
    wire [31:0] rdata1_to_ex;
    wire [31:0] rdata2_to_ex;
    wire [31:0] imm32_to_ex;
    wire [4:0] rd_addr_to_ex;
    wire [4:0] rs1_addr_to_ex;
    wire [4:0] rs2_addr_to_ex;
    wire [31:0] pc_to_ex;
    wire [31:0] pc_plus_4_to_ex;
    wire regWrite_ctrl_to_ex;
    wire ALUSrc_ctrl_to_ex;
    wire [3:0] ALUOp_ctrl_to_ex;
    wire branch_ctrl_to_ex;
    wire jump_ctrl_to_ex;
    wire isLoad_ctrl_to_ex;
    wire isStore_ctrl_to_ex;
    // wire isEcall_ctrl_to_ex;
    // wire [1:0] ecall_type_to_ex;
    InstructionDecode_ID_Stage u_id_stage (
        .clk(clk),
        .reset(reset),
        .instruction_ifid(instruction_to_id),
        .pc_ifid(pc_current_to_id),
        .reg_write_enable_from_wb(reg_write_enable_from_wb),
        .write_addr_from_wb(write_addr_from_wb),
        .write_data_from_wb(write_data_from_wb),
        .rdata1_to_ex(rdata1_to_ex),
        .rdata2_to_ex(rdata2_to_ex),
        .imm32_to_ex(imm32_to_ex),
        .rd_addr_to_ex(rd_addr_to_ex),
        .rs1_addr_to_ex(rs1_addr_to_ex),
        .rs2_addr_to_ex(rs2_addr_to_ex),
        .pc_to_ex(pc_to_ex),
        .pc_plus_4_to_ex(pc_plus_4_to_ex),
        .regWrite_ctrl_to_ex(regWrite_ctrl_to_ex),
        .ALUSrc_ctrl_to_ex(ALUSrc_ctrl_to_ex),
        .ALUOp_ctrl_to_ex(ALUOp_ctrl_to_ex),
        .branch_ctrl_to_ex(branch_ctrl_to_ex),
        .jump_ctrl_to_ex(jump_ctrl_to_ex),
        .isLoad_ctrl_to_ex(isLoad_ctrl_to_ex),
        .isStore_ctrl_to_ex(isStore_ctrl_to_ex)
        // .isEcall_ctrl_to_ex(isEcall_ctrl_to_ex),
        // .ecall_type_to_ex(ecall_type_to_ex)

    );


    wire idex_enable_write; //占位
    assign idex_enable_write = 1'b1; // 假设总是允许写入



    wire [31:0] rdata1_idex_to_ex;
    wire [31:0] rdata2_idex_to_ex;
    wire [31:0] imm32_idex_to_ex;
    wire [4:0] rd_addr_idex_to_ex;
    wire [4:0] rs1_addr_idex_to_ex;
    wire [4:0] rs2_addr_idex_to_ex;
    wire [31:0] pc_idex_to_ex;
    wire [31:0] pc_plus_4_idex_to_ex;
    wire regWrite_ctrl_idex_to_ex;
    wire ALUSrc_ctrl_idex_to_ex;
    wire [3:0] ALUOp_ctrl_idex_to_ex;
    wire branch_ctrl_idex_to_ex;
    wire jump_ctrl_idex_to_ex;
    wire isLoad_ctrl_idex_to_ex;
    wire isStore_ctrl_idex_to_ex;
    IDEX_PipelineRegister u_idex_reg (
        //input
        .clk(clk),
        .reset(reset),
        .enable_write(idex_enable_write), 
        .flush_idex(1'b0),   // 假设没有冲刷信号
        .rdata1_from_id(rdata1_to_ex),
        .rdata2_from_id(rdata2_to_ex),
        .imm32_from_id(imm32_to_ex),
        .rd_addr_from_id(rd_addr_to_ex),
        .rs1_addr_from_id(rs1_addr_to_ex),
        .rs2_addr_from_id(rs2_addr_to_ex),
        .pc_from_id(pc_to_ex),
        .ecall_type_from_id(2'b00),
        .regWrite_ctrl_from_id(regWrite_ctrl_to_ex),
        .ALUSrc_ctrl_from_id(ALUSrc_ctrl_to_ex),
        .ALUOp_ctrl_from_id(ALUOp_ctrl_to_ex),
        .branch_ctrl_from_id(branch_ctrl_to_ex),
        .jump_ctrl_from_id(jump_ctrl_to_ex),
        .isLoad_ctrl_from_id(isLoad_ctrl_to_ex),
        .isStore_ctrl_from_id(isStore_ctrl_to_ex),
        .isEcall_ctrl_from_id(1'b0),
        //output
        .rdata1_to_ex(rdata1_idex_to_ex),
        .rdata2_to_ex(rdata2_idex_to_ex),
        .imm32_to_ex(imm32_idex_to_ex),
        .rd_addr_to_ex(rd_addr_idex_to_ex),
        .rs1_addr_to_ex(rs1_addr_idex_to_ex),
        .rs2_addr_to_ex(rs2_addr_idex_to_ex),
        .pc_to_ex(pc_idex_to_ex),
        .ecall_type_to_ex(2'b00),
        .regWrite_ctrl_to_ex(regWrite_ctrl_idex_to_ex),
        .ALUSrc_ctrl_to_ex(ALUSrc_ctrl_idex_to_ex),
        .ALUOp_ctrl_to_ex(ALUOp_ctrl_idex_to_ex),
        .branch_ctrl_to_ex(branch_ctrl_idex_to_ex),
        .jump_ctrl_to_ex(jump_ctrl_idex_to_ex),
        .isLoad_ctrl_to_ex(isLoad_ctrl_idex_to_ex),
        .isStore_ctrl_to_ex(isStore_ctrl_idex_to_ex),
        .isEcall_ctrl_to_ex(1'b0)

    );

    // wire isEcall_ctrl_idex_to_ex;
    


    wire alu_result_to_exmem;
    wire branch_condition_met_to_exmem;
    wire branch_target_addr_to_exmem;
    wire rdata2_for_store_to_exmem;
    wire rd_addr_to_exmem;
    wire MemRead_to_exmem;
    wire MemWrite_to_exmem;
    wire IORead_to_exmem;
    wire IOWrite_to_exmem;
    wire MemToReg_to_exmem; 

    Execute_Stage_Wrapper u_exe (
        //input
        .clk(clk),
        .reset(reset),
        .rdata1_from_idex(rdata1_idex_to_ex),
        .rdata2_from_idex(rdata2_idex_to_ex),
        .imm32_from_idex(imm32_idex_to_ex),
        .pc_from_idex(pc_idex_to_ex),
        .rd_addr_from_idex(rd_addr_idex_to_ex),
        .regWrite_ctrl_from_idex(regWrite_ctrl_idex_to_ex),
        .ALUSrc_ctrl_from_idex(ALUSrc_ctrl_idex_to_ex),
        .ALUOp_ctrl_from_idex(ALUOp_ctrl_idex_to_ex),
        .branch_ctrl_from_idex(branch_ctrl_idex_to_ex),
        .jump_ctrl_from_idex(jump_ctrl_idex_to_ex),
        .isLoad_ctrl_from_idex(isLoad_ctrl_idex_to_ex),
        .isStore_ctrl_from_idex(isStore_ctrl_idex_to_ex),
        //output
        .alu_result_addr_to_exmem(alu_result_to_exmem),
        .rdata2_for_store_to_exmem(rdata2_for_store_to_exmem),
        .rd_addr_to_exmem(rd_addr_to_exmem),
        .MemRead_ctrl_to_exmem(MemRead_to_exmem),
        .MemWrite_ctrl_to_exmem(MemWrite_to_exmem),
        .IORead_ctrl_to_exmem(IORead_to_exmem),
        .IOWrite_ctrl_to_exmem(IOWrite_to_exmem),
        .RegWrite_ctrl_to_exmem(RegWrite_ctrl_to_exmem),
        .MemToReg_ctrl_to_exmem(MemToReg_to_exmem),
        .branch_or_jump_to_if(branch),
        .target_pc_ex(target_pc_in_if)
    );



    wire [31:0] alu_result_to_mem;
    wire [31:0] branch_target_addr_to_mem;
    wire [31:0] rdata2_for_store_to_mem;
    wire [4:0]  rd_addr_to_mem;
    wire [31:0] pc_to_mem;
    wire [31:0] pc_plus_4_to_mem;
    wire final_RegWrite_ctrl; //直接to WB
    wire MemRead_ctrl_to_mem;
    wire MemWrite_ctrl_to_mem;
    wire IORead_ctrl_to_mem;
    wire IOWrite_ctrl_to_mem;
    wire MemToReg_ctrl_to_mem;

    EXMEM_PipelineRegister u_exmem_reg (
        //input
        .clk(clk),
        .reset(reset),
        .enable_write(1'b1), // 假设总是允许写入
        .flush_exmem(1'b0),  // 假设没有冲刷信号
        .alu_result_from_ex(alu_result_to_exmem),
        .branch_target_addr_from_ex(branch_target_addr_to_exmem),
        .rdata2_for_store_from_ex(rdata2_for_store_to_exmem),
        .rd_addr_from_ex(rd_addr_to_exmem),
        // .pc_from_ex(pc_current_to_id),
        // .pc_plus_4_from_ex(pc_plus_4_to_id),

        .final_RegWrite_ctrl_from_ex(RegWrite_ctrl_to_exmem),
        

        .MemRead_ctrl_from_ex(MemRead_to_exmem),
        .MemWrite_ctrl_from_ex(MemWrite_to_exmem),
        .IORead_ctrl_from_ex(IORead_to_exmem),
        .IOWrite_ctrl_from_ex(IOWrite_to_exmem),
        .MemToReg_ctrl_from_ex(MemToReg_to_exmem),
        //output
        .alu_result_to_mem(alu_result_to_mem),
        .branch_target_addr_to_mem(branch_target_addr_to_mem),
        .rdata2_for_store_to_mem(rdata2_for_store_to_mem),
        .rd_addr_to_mem(rd_addr_to_mem),
        // .pc_to_mem(pc_to_mem),
        // .pc_plus_4_to_mem(pc_plus_4_to_mem),


        .final_RegWrite_ctrl_to_mem(final_RegWrite_ctrl),
        
        
        .MemRead_ctrl_to_mem(MemRead_ctrl_to_mem),
        .MemWrite_ctrl_to_mem(MemWrite_ctrl_to_mem),
        .IORead_ctrl_to_mem(IORead_ctrl_to_mem),
        .IOWrite_ctrl_to_mem(IOWrite_ctrl_to_mem),
        .MemToReg_ctrl_to_mem(MemToReg_ctrl_to_mem)
    );


    wire [31:0] data_read_from_dmem;
    wire [15:0] data_read_from_io;

    wire [31:0] data_read_to_wb;
    wire [31:0] addr_to_dmem_io;
    wire [31:0] data_to_write_to_dmem_io;
    wire led_write_enable_to_io;
    wire switch_read_enable_to_io;

    MemOrIO_Pipeline u_memorio (
        //input
        .MemRead_ctrl_from_exmem(MemRead_ctrl_to_mem),
        .MemWrite_ctrl_from_exmem(MemWrite_ctrl_to_mem),
        .IORead_ctrl_from_exmem(IORead_ctrl_to_mem),
        .IOWrite_ctrl_from_exmem(IOWrite_ctrl_to_mem),
        .alu_result_addr_from_exmem(alu_result_to_mem),
        .rdata2_for_store_from_exmem(rdata2_for_store_to_mem),
        .data_read_from_dmem(data_read_from_dmem),
        .data_read_from_io(data_read_from_io),

        //output
        .data_read_to_memwb(data_read_to_wb),
        .addr_to_dmem_io(addr_to_dmem_io),
        .data_to_write_to_dmem_io(data_to_write_to_dmem_io),
        .led_write_enable_to_io(led_write_enable_to_io),
        .switch_read_enable_to_io(switch_read_enable_to_io)
    );


    DMem u_dmem (
        .clk(clk),
        .MemRead(MemRead_ctrl_to_mem),
        .MemWrite(MemWrite_ctrl_to_mem),
        .addr(addr_to_dmem_io),
        .din(data_to_write_to_dmem_io), 
        .dout(data_read_from_dmem)
    );



    wire  [BUTTON_WIDTH-1:0]  button_physical_in;    //占位
    wire [6:0]  seg_physical_out; //占位
    wire [3:0]  an_physical_out; //占位


    IOModule  #(
        .BUTTON_WIDTH(BUTTON_WIDTH),
        .DIP_WIDTH(DIP_WIDTH),
        .LED_WIDTH(LED_WIDTH)) u_io (
        .clk(clk),
        .io_address(addr_to_dmem_io),
        .io_writeData(data_to_write_to_dmem_io),
        .io_access_write_enable(IOWrite_ctrl_to_mem),
        .io_access_read_enable(IORead_ctrl_to_mem),
        .button_physical_in(button_physical_in), // 来自按钮的物理输入
        .switch_read_enable(switch_read_enable_to_io), // 开关读使能信号
        .led_write_enable(led_write_enable_to_io), // LED写使能信号
        .dipSwitch_physical_in(switch_in), // 来自switch的物理输入 
        //output
        .io_readData_out(data_read_from_io),  // 从选定I/O设备读取的数据 (送回MemOrIO)
        .led_physical_out(led_out), // 输出到8位LED阵列的物理信号
        .seg_physical_out(seg_physical_out), // 输出到七段数码管段码的物理信号 (a–g)
        .an_physical_out(an_physical_out) // 输出到七段数码管位选的物理信号
    );
        wire [31:0] alu_result_to_wb;
        wire [31:0] data_read_from_mem_to_wb;
        wire [4:0]  rd_addr_to_wb;
        wire final_RegWrite_ctrl_to_wb;
        wire MemToReg_ctrl_to_wb;
        MEMWB_PipelineRegister u_memwb_reg (
            .clk(clk),
            .reset(reset),
            .alu_result_from_mem(alu_result_to_mem),
            .data_read_from_mem(data_read_to_wb),
            .rd_addr_from_mem(rd_addr_to_mem),
            .final_RegWrite_ctrl_from_mem(final_RegWrite_ctrl),
            .MemToReg_ctrl_from_mem(MemToReg_ctrl_to_mem),
            .alu_result_to_wb(alu_result_to_wb),
            .data_read_from_mem_to_wb(data_read_from_mem_to_wb),
            .rd_addr_to_wb(rd_addr_to_wb),
            .final_RegWrite_ctrl_to_wb(final_RegWrite_ctrl_to_wb),
            .MemToReg_ctrl_to_wb(MemToReg_ctrl_to_wb)
        );




        WriteBack_Stage u_wb (
            //input
            .alu_result_from_memwb(alu_result_to_wb),
            .data_read_from_mem_from_memwb(data_read_from_mem_to_wb),
            .rd_addr_from_memwb(rd_addr_to_wb),
            .final_RegWrite_ctrl_from_memwb(final_RegWrite_ctrl_to_wb),
            .MemToReg_ctrl_from_memwb(MemToReg_ctrl_to_wb),
            //output
            .write_data_to_regfile(write_data_from_wb),
            .write_addr_to_regfile(write_addr_from_wb),
            .reg_write_enable_to_regfile(reg_write_enable_from_wb)
        );

        assign stall_if = !(ifid_enable_write && idex_enable_write);



    



endmodule
