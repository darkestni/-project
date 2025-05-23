module PipelineCPU_Test (
    input clk,
    input reset,

    //for test (existing)
    output wire [31:0] x1,
    output wire [31:0] x2,
    output wire [31:0] x3,
    output wire [31:0] x4,
    output wire [31:0] x5,

    input debugMode,
    input [31:0] testScenario,

    // --- New Debug Outputs ---
    // IF Stage
    output wire [31:0] debug_if_pc_current,         // Current PC in IF
    output wire [31:0] debug_if_instruction_out,    // Instruction fetched by IF (to IF/ID)
    output wire [31:0] debug_if_pc_reg,
    output wire [31:0] debug_if_instruction_from_prgrom, // Instruction from ROM

    // IF/ID Register Outputs (Inputs to ID Stage)
    output wire [31:0] debug_ifid_instruction,
    output wire [31:0] debug_ifid_pc,
    output wire        debug_ifid_enable_write_actual, // Actual enable for IF/ID reg

    // ID Stage Outputs (Inputs to ID/EX Register)
    output wire [31:0] debug_id_rdata1,             // rs1 data from RegFile
    output wire [31:0] debug_id_rdata2,             // rs2 data from RegFile
    output wire [31:0] debug_id_imm32,
    output wire [4:0]  debug_id_rd_addr,
    output wire [4:0]  debug_id_rs1_addr,
    output wire [4:0]  debug_id_rs2_addr,
    output wire        debug_id_regWrite_ctrl,
    output wire [3:0]  debug_id_ALUOp_ctrl,
    output wire        debug_id_ALUSrc_ctrl,
    output wire        debug_id_branch_ctrl,
    output wire        debug_id_jump_ctrl,
    output wire        debug_id_isLoad_ctrl,
    output wire        debug_id_isStore_ctrl,

    // ID/EX Register Outputs (Inputs to EX Stage)
    output wire [31:0] debug_idex_pc,
    output wire [4:0]  debug_idex_rd_addr,
    output wire [4:0]  debug_idex_rs1_addr,
    output wire [4:0]  debug_idex_rs2_addr,
    output wire [31:0] debug_idex_rdata1,
    output wire [31:0] debug_idex_rdata2,
    output wire [31:0] debug_idex_imm32,
    output wire        debug_idex_regWrite_ctrl,
    output wire [3:0]  debug_idex_ALUOp_ctrl,
    output wire        debug_idex_ALUSrc_ctrl,
    output wire        debug_idex_branch_ctrl,
    output wire        debug_idex_jump_ctrl,
    output wire        debug_idex_isLoad_ctrl,
    output wire        debug_idex_isStore_ctrl,
    output wire [1:0]  debug_idex_forwardA,        // ForwardA from IDEX to EX
    output wire [1:0]  debug_idex_forwardB,        // ForwardB from IDEX to EX
    output wire        debug_idex_enable_write_actual, // Actual enable for IDEX reg
    output wire        debug_idex_flush_actual,        // Actual flush for IDEX reg


    // EX Stage Outputs (Inputs to EX/MEM Register)
    output wire [31:0] debug_ex_alu_result,
    output wire [4:0]  debug_ex_rd_addr,
    output wire        debug_ex_regWrite_ctrl,
    output wire        debug_ex_MemRead_ctrl,
    output wire        debug_ex_MemWrite_ctrl,
    output wire        debug_ex_MemToReg_ctrl,
    output wire        debug_ex_branch_taken,      // branch_or_jump_to_if
    output wire [31:0] debug_ex_target_pc,
    output wire [31:0] ex_alu_operand_a,
    output wire [31:0] ex_alu_operand_b,

    // EX/MEM Register Outputs (Inputs to MEM Stage)
    output wire [31:0] debug_exmem_alu_result,
    output wire [4:0]  debug_exmem_rd_addr,
    output wire [31:0] debug_exmem_rdata2_store,
    output wire        debug_exmem_regWrite_ctrl,
    output wire        debug_exmem_MemRead_ctrl,
    output wire        debug_exmem_MemWrite_ctrl,
    output wire        debug_exmem_IORead_ctrl,    // Added
    output wire        debug_exmem_IOWrite_ctrl,   // Added
    output wire        debug_exmem_MemToReg_ctrl,

    // MEM Stage Outputs (Inputs to MEM/WB Register)
    output wire [31:0] debug_mem_data_read,        // Data read from DMEM/IO
    // (MEM/WB pass-throughs are mostly covered by MEM/WB reg outputs)

    // MEM/WB Register Outputs (Inputs to WB Stage)
    output wire [31:0] debug_memwb_alu_result,
    output wire [31:0] debug_memwb_data_read,
    output wire [4:0]  debug_memwb_rd_addr,
    output wire        debug_memwb_regWrite_ctrl,
    output wire        debug_memwb_MemToReg_ctrl,

    // WB Stage Outputs (To Register File)
    output wire [31:0] debug_wb_writeData,
    output wire [4:0]  debug_wb_writeAddr,
    output wire        debug_wb_regWriteEnable,

    // Hazard Unit Signals
    output wire debug_stall_if_internal,        // stall_if driven by DataHazardDetect
    output wire debug_ifid_stall_internal,      // ifid_stall from DataHazardDetect
    output wire debug_idex_flush_internal,      // idex_flush (idex_nop) from DataHazardDetect
    output wire [1:0] debug_forwardA_from_fwd_unit, // Direct output from ForwardingUnit
    output wire [1:0] debug_forwardB_from_fwd_unit, // Direct output from ForwardingUnit
    //wire to forwarding unit
    output wire [4:0] rs2_addr_from_id,
    output wire [4:0] rd_addr_to_mem,
    output wire final_RegWrite_ctrl,


    // --- End New Debug Outputs ---




    input  [15:0] switch_in,
    output [15:0] led_out
);
  localparam BUTTON_WIDTH = 3; 
    localparam DIP_WIDTH = 16; // 假设拨码开关宽度为16位
    localparam LED_WIDTH = 16; 
      wire [1:0] forwardA_to_ex;
      wire [1:0] forwardB_to_ex;
    wire branch;
    wire [31:0] target_pc_in_if;
    wire stall_if; //占位
    // reg debugMode = 1'b1; 
    // reg [31:0] testScenario = 32'd0; // 测试场景输入
    wire [31:0] instruction_to_ifid;
    wire [31:0] pc_current_to_ifid;
    wire [31:0] pc_plus_4_to_ifid;
    wire [1:0] forwardA_from_idex;
    wire [1:0] forwardB_from_idex;
    wire idex_nop;

    // wire [1:0] forwardB_to_ex;
    wire [31:0] alu_result_to_wb;
    // wire [31:0] data_read_from_mem_to_wb;
    wire [4:0]  rd_addr_to_wb;
    wire final_RegWrite_ctrl_to_wb;
    wire MemToReg_ctrl_to_wb;
    wire [31:0] alu_result_to_mem;
    wire [31:0] branch_target_addr_to_mem;
    wire [31:0] rdata2_for_store_to_mem;
    // wire [4:0]  rd_addr_to_mem;
    wire [31:0] pc_to_mem;
    wire [31:0] pc_plus_4_to_mem;
    // wire final_RegWrite_ctrl; //直接to WB
    wire MemRead_ctrl_to_mem;
    wire MemWrite_ctrl_to_mem;
    wire IORead_ctrl_to_mem;
    wire IOWrite_ctrl_to_mem;
    wire MemToReg_ctrl_to_mem;
    wire [31:0] data_read_memwb_to_wb;
    assign debug_if_pc_reg = pc_current_to_ifid;
    IFetch u_ifetch (
        .clk(clk),
        .reset(reset),
        .branch(branch),
        // .pc_reg(debug_if_pc_reg),
        .target_pc_in_if(target_pc_in_if),
        .stall_if(stall_if),
        .debugMode(debugMode),
        .testScenario(testScenario),
        // .bram_instruction_data(debug_if_instruction_from_prgrom), // 来自指令存储器的指令
        .bram_instruction_data(instruction_to_ifid),
        .pc_current_to_ifid(pc_current_to_ifid)
        // .pc_plus_4_to_ifid(pc_plus_4_to_ifid) 
    );
    // wire [31:0] rom_instruction_data;
    // PC u_pc (
    //     .clk(clk),
    //     .reset(reset),
    //     .stall_pc(stall_if), // 暂停PC更新
    //     .branch(branch), // 是否进行分支/跳转
    //     .branch_target_pc(target_pc_in_if), // 分支/跳转的目标PC
    //     .current_pc_out(pc_current_to_ifid) // 当前PC值
    // );
    // prgrom u_instr_rom (
    //     .clka(clk),                 // Assuming prgrom is synchronous
    //     .addra(pc_current_to_ifid[15:2]), // Example: Use bits 15 down to 2 for word addressing
    //                                 // Adjust this based on your prgrom's address input width
    //                                 // and how your PC maps to ROM addresses.
    //     .douta(rom_instruction_data)
    // );

    // InstructionMemory u_instruction_memory (
    //     .clk(clk),
    //     .reset(reset),
    //     .Instruction_prgrom(rom_instruction_data),
    //     .pc_address_in(pc_current_to_ifid), // 当前PC值
    //     .debugMode_in(debugMode),
    //     .testScenario_in(testScenario),
    //     .instruction_out_final(instruction_to_ifid) // 获取到的指令
    // );
    // assign debug_if_instruction_from_prgrom = instruction_to_ifid;




    wire ifid_stall;
    // assign ifid_enable_write = 1'b1; // 占位
    wire ifid_flush_ifid;
    wire [31:0] instruction_to_id;
    wire [31:0] pc_current_to_id;
    // wire [31:0] pc_plus_4_to_id;
    assign ifid_flush_ifid = branch;


    IFID_PipelineRegister u_ifid_reg (
        .clk(clk),
        .reset(reset),
        .enable_write(!ifid_stall), // 这里假设总是允许写入
        .flush_ifid(ifid_flush_ifid),   // 假设没有冲刷信号
        .instruction_from_if(instruction_to_ifid),
        .pc_current_from_if(pc_current_to_ifid),
        // .pc_plus_4_from_if(pc_plus_4_to_ifid),
        .instruction_to_id(instruction_to_id),
        .pc_current_to_id(pc_current_to_id)
        // .pc_plus_4_to_id(pc_plus_4_to_id)
    );


    wire [4:0]write_addr_from_wb;
    wire [31:0]write_data_from_wb;
    wire [31:0] rdata1_to_ex;
    wire [31:0] rdata2_to_ex;
    wire [31:0] imm32_to_ex;
    wire [4:0] rd_addr_to_ex;
    wire [4:0] rs1_addr_to_ex;
    wire [4:0] rs2_addr_to_ex;
    wire [31:0] pc_to_ex;
    // wire [31:0] pc_plus_4_to_ex;
    wire regWrite_ctrl_to_ex;
    wire ALUSrc_ctrl_to_ex;
    wire [3:0] ALUOp_ctrl_to_ex;
    wire branch_ctrl_to_ex;
    wire jump_ctrl_to_ex;
    wire isLoad_ctrl_to_ex;
    wire isStore_ctrl_to_ex;
    wire isEcall_ctrl_to_ex;
    wire [1:0] ecall_type_to_ex;
    wire [4:0] rd_addr_from_id;
    wire [4:0] rs1_addr_from_id;
    wire [2:0] funct3_from_id;
    wire [6:0] funct7_from_id;
    // wire [4:0] rs2_addr_from_id;
    InstructionDecode_ID_Stage u_id_stage (
        .clk(clk),
        .reset(reset),
        .instruction_ifid(instruction_to_id),
        .pc_ifid(pc_current_to_id),
        .reg_write_enable_from_wb(reg_write_enable_from_wb),
        .write_addr_from_wb(write_addr_from_wb),
        .write_data_from_wb(write_data_from_wb),

        //for test
        .x1(x1),
        .x2(x2),
        .x3(x3),
        .x4(x4),
        .x5(x5),


        //output
        .rdata1_to_ex(rdata1_to_ex),
        .rdata2_to_ex(rdata2_to_ex),
        .imm32_to_ex(imm32_to_ex),
        .rd_addr_to_ex(rd_addr_from_id),
        .rs1_addr_to_ex(rs1_addr_from_id),
        .rs2_addr_to_ex(rs2_addr_from_id),
        .pc_to_ex(pc_to_ex),
        // .pc_plus_4_to_ex(pc_plus_4_to_ex),
        .regWrite_ctrl_to_ex(regWrite_ctrl_to_ex),
        .ALUSrc_ctrl_to_ex(ALUSrc_ctrl_to_ex),
        .ALUOp_ctrl_to_ex(ALUOp_ctrl_to_ex),
        .branch_ctrl_to_ex(branch_ctrl_to_ex),
        .jump_ctrl_to_ex(jump_ctrl_to_ex),
        .isLoad_ctrl_to_ex(isLoad_ctrl_to_ex),
        .isStore_ctrl_to_ex(isStore_ctrl_to_ex),
        .funct3_w(funct3_from_id),
        .funct7_w(funct7_from_id)
        // .isEcall_ctrl_to_ex(isEcall_ctrl_to_ex),
        // .ecall_type_to_ex(ecall_type_to_ex)

    );


    wire idex_enable_write; //占位
    assign idex_enable_write = 1'b1; // 假设总是允许写入

    wire [2:0] funct3_to_ex;
    wire [6:0] funct7_to_ex;

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
    wire idex_flush;
    assign idex_flush = branch;

    //     ForwardingUnit u_forwarding_unit (
    //     .id_ex_rs1(rs1_addr_idex_to_ex),
    //     .id_ex_rs2(rs2_addr_idex_to_ex),
    //     .ex_mem_rd(rd_addr_to_mem),
    //     .ex_mem_regWrite(final_RegWrite_ctrl),
    //     .mem_wb_rd(rd_addr_to_wb),
    //     .mem_wb_regWrite(final_RegWrite_ctrl_to_wb),
    //     .forwardA(forwardA_from_idex),
    //     .forwardB(forwardB_from_idex)
    // );
    wire flush_idex;
    assign flush_idex = idex_nop || branch;
    IDEX_PipelineRegister u_idex_reg (
        //input
        .clk(clk),
        .reset(reset),
        .enable_write(idex_enable_write), 
        .flush_idex(flush_idex),   
        .rdata1_from_id(rdata1_to_ex),
        .rdata2_from_id(rdata2_to_ex),
        .imm32_from_id(imm32_to_ex),
        .rd_addr_from_id(rd_addr_from_id),
        .rs1_addr_from_id(rs1_addr_from_id),
        .rs2_addr_from_id(rs2_addr_from_id),
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
        .funct3_from_id(funct3_from_id),
        .funct7_from_id(funct7_from_id),
        // .forwardA_from_id(forwardA_from_idex),
        // .forwardB_from_id(forwardB_from_idex),
        //output
        .rdata1_to_ex(rdata1_idex_to_ex),
        .rdata2_to_ex(rdata2_idex_to_ex),
        .imm32_to_ex(imm32_idex_to_ex),
        .rd_addr_to_ex(rd_addr_idex_to_ex),
        .rs1_addr_to_ex(rs1_addr_idex_to_ex),
        .rs2_addr_to_ex(rs2_addr_idex_to_ex),
        .pc_to_ex(pc_idex_to_ex),
        .ecall_type_to_ex(ecall_type_to_ex),
        .regWrite_ctrl_to_ex(regWrite_ctrl_idex_to_ex),
        .ALUSrc_ctrl_to_ex(ALUSrc_ctrl_idex_to_ex),
        .ALUOp_ctrl_to_ex(ALUOp_ctrl_idex_to_ex),
        .branch_ctrl_to_ex(branch_ctrl_idex_to_ex),
        .jump_ctrl_to_ex(jump_ctrl_idex_to_ex),
        .isLoad_ctrl_to_ex(isLoad_ctrl_idex_to_ex),
        .isStore_ctrl_to_ex(isStore_ctrl_idex_to_ex),
        .isEcall_ctrl_to_ex(isEcall_ctrl_to_ex),
        .funct3_to_ex(funct3_to_ex),
        .funct7_to_ex(funct7_to_ex)
        // .forwardA_to_ex(forwardA_to_ex),
        // .forwardB_to_ex(forwardB_to_ex)

    );

    // wire isEcall_ctrl_idex_to_ex;
    


    wire [31:0]alu_result_to_exmem;
    wire branch_condition_met_to_exmem;
    wire branch_target_addr_to_exmem;
    wire [31:0]rdata2_for_store_to_exmem;
    wire [4:0]rd_addr_to_exmem;
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
        .forwardA_from_idex(forwardA_to_ex),
        .forwardB_from_idex(forwardB_to_ex),
        .memwb_write_to_reg(write_data_from_wb),
        .exmem_alu_result(alu_result_to_mem),
        //output
    // reg  [31:0] alu_operand_a;
    // reg  [31:0] alu_operand_b;
        .alu_operand_a(ex_alu_operand_a),
        .alu_operand_b(ex_alu_operand_b),
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


    wire [2:0] funct3_to_mem;
    wire [6:0] funct7_to_mem;


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
        .funct3_from_ex(funct3_to_ex),
        .funct7_from_ex(funct7_to_ex),
        //output
        .alu_result_to_mem(alu_result_to_mem),
        .branch_target_addr_to_mem(branch_target_addr_to_mem),
        .rdata2_for_store_to_mem(rdata2_for_store_to_mem),
        .rd_addr_to_mem(rd_addr_to_mem),
        // .pc_to_mem(pc_to_mem),
        // .pc_plus_4_to_mem(pc_plus_4_to_mem),


        .final_RegWrite_ctrl_to_mem(final_RegWrite_ctrl),
        .funct3_to_mem(funct3_to_mem),
        .funct7_to_mem(funct7_to_mem),
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


    // DMem u_dmem (
    //     .clk(clk),
    //     .MemRead(MemRead_ctrl_to_mem),
    //     .MemWrite(MemWrite_ctrl_to_mem),
    //     .addr(addr_to_dmem_io),
    //     .din(data_to_write_to_dmem_io), 
    //     .dout(data_read_from_dmem)
    // );
    DMem u_DMem (
        .clk(clk),
        .MemRead(MemRead_ctrl_to_mem),
        .MemWrite(MemWrite_ctrl_to_mem),
        .mem_width(funct3_to_mem[1:0]),
        .sign_ext(~funct3_to_mem[2]),
        .addr(addr_to_dmem_io),       
        .din(data_to_write_to_dmem_io), // 使用MemOrIO处理后的写数据
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
        .seg_data_out(seg_physical_out) // 输出到七段数码管段码的物理信号 (a–g)
    );



        MEMWB_PipelineRegister u_memwb_reg (
            .clk(clk),
            .reset(reset),
            .alu_result_from_mem(alu_result_to_mem),
            .data_read_from_mem(data_read_to_wb),
            .rd_addr_from_mem(rd_addr_to_mem),
            .final_RegWrite_ctrl_from_mem(final_RegWrite_ctrl),
            .MemToReg_ctrl_from_mem(MemToReg_ctrl_to_mem),
            //output
            .alu_result_to_wb(alu_result_to_wb),
            .data_read_from_mem_to_wb(data_read_memwb_to_wb),
            .rd_addr_to_wb(rd_addr_to_wb),
            .final_RegWrite_ctrl_to_wb(final_RegWrite_ctrl_to_wb),
            .MemToReg_ctrl_to_wb(MemToReg_ctrl_to_wb)
        );


        WriteBack_Stage u_wb (
            //input
            .alu_result_from_memwb(alu_result_to_wb),
            .data_read_from_mem_from_memwb(data_read_memwb_to_wb),
            .rd_addr_from_memwb(rd_addr_to_wb),
            .final_RegWrite_ctrl_from_memwb(final_RegWrite_ctrl_to_wb),
            .MemToReg_ctrl_from_memwb(MemToReg_ctrl_to_wb),
            //output
            .write_data_to_regfile(write_data_from_wb),
            .write_addr_to_regfile(write_addr_from_wb),
            .reg_write_enable_to_regfile(reg_write_enable_from_wb)
        );

        DataHazardDetect u_data_hazard (
            .ex_isLoad(MemRead_to_exmem || IORead_to_exmem),
            .ex_rd_addr(rd_addr_to_exmem),
            .id_rs1_addr(rs1_addr_from_id),
            .id_rs2_addr(rs2_addr_from_id),
            .pc_stall(stall_if),
            .ifid_stall(ifid_stall), // 占位
            .idex_nop(idex_nop) 
        );
//         module DataHazardDetect (
//     // Inputs from ID/EX pipeline register (EX stage's current instruction info)
//     input        exmem_isLoad,    // Is the instruction currently in EX a Load?
//     input [4:0]  exmem_rd_addr,   // Destination register of the instruction in EX

//     // Inputs from IF/ID pipeline register (ID stage's current instruction info)
//     // More accurately, these should be the rs1/rs2 from the instruction *currently in ID*,
//     // which are the outputs of the ID stage's decoder, *before* they get latched by ID/EX.
//     // Your connections: .id_rs1_addr(rs1_addr_from_id), .id_rs2_addr(rs2_addr_from_id)
//     // This is correct if rs1_addr_from_id and rs2_addr_from_id are the decoded source
//     // register addresses of the instruction currently being processed in the ID stage.
//     input [4:0]  id_rs1_addr,  // rs1 of the instruction currently in ID
//     input [4:0]  id_rs2_addr,  // rs2 of the instruction currently in ID

//     // Outputs to control pipeline
//     output reg pc_stall,       // Stall the PC and IF stage
//     output reg ifid_stall,     // Stall the IF/ID register (disable write)
//     output reg idex_nop        // Insert NOP into ID/EX register (effectively flush ID's output)
// );


        // assign stall_if = !(ifid_enable_write && idex_enable_write);
        // assign ifid_flush_ifid = !(stall_if && branch_condition_met_to_exmem);

        // assign idex_flush = !(stall_if && branch_condition_met_to_exmem);


    ForwardingUnit u_forwarding_unit (
        .id_ex_rs1(rs1_addr_idex_to_ex),
        .id_ex_rs2(rs2_addr_idex_to_ex),
        .ex_mem_rd(rd_addr_to_mem),
        .ex_mem_regWrite(final_RegWrite_ctrl),
        .mem_wb_rd(rd_addr_to_wb),
        .mem_wb_regWrite(final_RegWrite_ctrl_to_wb),
        .forwardA(forwardA_to_ex),
        .forwardB(forwardB_to_ex)
    );



    
    // ... (existing assignments and module instantiations) ...

    // --- Assignments for New Debug Outputs ---
    // IF Stage
    assign debug_if_pc_current      = pc_current_to_ifid; // PC going into IF/ID
    assign debug_if_instruction_out = instruction_to_ifid; // Instruction going into IF/ID

    // IF/ID Register Outputs
    assign debug_ifid_instruction    = instruction_to_id;
    assign debug_ifid_pc             = pc_current_to_id;
    assign debug_ifid_enable_write_actual = !ifid_stall; // What actually controls the write

    // ID Stage Outputs (Inputs to ID/EX Register)
    assign debug_id_rdata1          = rdata1_to_ex;
    assign debug_id_rdata2          = rdata2_to_ex;
    assign debug_id_imm32           = imm32_to_ex;
    assign debug_id_rd_addr         = rd_addr_from_id; // Output from ID stage before ID/EX reg
    assign debug_id_rs1_addr        = rs1_addr_from_id;
    assign debug_id_rs2_addr        = rs2_addr_from_id;
    assign debug_id_regWrite_ctrl   = regWrite_ctrl_to_ex;
    assign debug_id_ALUOp_ctrl      = ALUOp_ctrl_to_ex;
    assign debug_id_ALUSrc_ctrl     = ALUSrc_ctrl_to_ex;
    assign debug_id_branch_ctrl     = branch_ctrl_to_ex;
    assign debug_id_jump_ctrl       = jump_ctrl_to_ex;
    assign debug_id_isLoad_ctrl     = isLoad_ctrl_to_ex;
    assign debug_id_isStore_ctrl    = isStore_ctrl_to_ex;

    // ID/EX Register Outputs
    assign debug_idex_pc             = pc_idex_to_ex;
    assign debug_idex_rd_addr        = rd_addr_idex_to_ex;
    assign debug_idex_rs1_addr       = rs1_addr_idex_to_ex;
    assign debug_idex_rs2_addr       = rs2_addr_idex_to_ex;
    assign debug_idex_rdata1         = rdata1_idex_to_ex;
    assign debug_idex_rdata2         = rdata2_idex_to_ex;
    assign debug_idex_imm32          = imm32_idex_to_ex;
    assign debug_idex_regWrite_ctrl  = regWrite_ctrl_idex_to_ex;
    assign debug_idex_ALUOp_ctrl     = ALUOp_ctrl_idex_to_ex;
    assign debug_idex_ALUSrc_ctrl    = ALUSrc_ctrl_idex_to_ex;
    assign debug_idex_branch_ctrl    = branch_ctrl_idex_to_ex;
    assign debug_idex_jump_ctrl      = jump_ctrl_idex_to_ex;
    assign debug_idex_isLoad_ctrl    = isLoad_ctrl_idex_to_ex;
    assign debug_idex_isStore_ctrl   = isStore_ctrl_idex_to_ex;
    assign debug_idex_forwardA       = forwardA_to_ex; // from IDEX reg output
    assign debug_idex_forwardB       = forwardB_to_ex; // from IDEX reg output
    assign debug_idex_enable_write_actual = idex_enable_write; // What actually controls the write
    assign debug_idex_flush_actual   = idex_flush; // Actual flush signal to IDEX

    // EX Stage Outputs
    assign debug_ex_alu_result    = alu_result_to_exmem;
    assign debug_ex_rd_addr       = rd_addr_to_exmem;
    assign debug_ex_regWrite_ctrl = RegWrite_ctrl_to_exmem;
    assign debug_ex_MemRead_ctrl  = MemRead_to_exmem;
    assign debug_ex_MemWrite_ctrl = MemWrite_to_exmem;
    assign debug_ex_MemToReg_ctrl = MemToReg_to_exmem;
    assign debug_ex_branch_taken  = branch; // branch_or_jump_to_if
    assign debug_ex_target_pc     = target_pc_in_if;

    // EX/MEM Register Outputs
    assign debug_exmem_alu_result    = alu_result_to_mem;
    assign debug_exmem_rd_addr       = rd_addr_to_mem;
    assign debug_exmem_rdata2_store  = rdata2_for_store_to_mem;
    assign debug_exmem_regWrite_ctrl = final_RegWrite_ctrl; // This is RegWrite from EXMEM to MEM
    assign debug_exmem_MemRead_ctrl  = MemRead_ctrl_to_mem;
    assign debug_exmem_MemWrite_ctrl = MemWrite_ctrl_to_mem;
    assign debug_exmem_IORead_ctrl   = IORead_ctrl_to_mem;    // Added
    assign debug_exmem_IOWrite_ctrl  = IOWrite_ctrl_to_mem;   // Added
    assign debug_exmem_MemToReg_ctrl = MemToReg_ctrl_to_mem;

    // MEM Stage Outputs
    assign debug_mem_data_read       = data_read_to_wb; // Data from MemOrIO to MEMWB reg

    // MEM/WB Register Outputs
    assign debug_memwb_alu_result    = alu_result_to_wb;
    assign debug_memwb_data_read     = data_read_memwb_to_wb; // Corrected wire name based on your MEMWB instance
    assign debug_memwb_rd_addr       = rd_addr_to_wb;
    assign debug_memwb_regWrite_ctrl = final_RegWrite_ctrl_to_wb;
    assign debug_memwb_MemToReg_ctrl = MemToReg_ctrl_to_wb;

    // WB Stage Outputs
    assign debug_wb_writeData        = write_data_from_wb;
    assign debug_wb_writeAddr        = write_addr_from_wb;
    assign debug_wb_regWriteEnable   = reg_write_enable_from_wb;

    // Hazard Unit Signals
    assign debug_stall_if_internal       = stall_if;
    assign debug_ifid_stall_internal     = ifid_stall;
    assign debug_idex_flush_internal     = idex_flush; // This is idex_nop from DataHazardDetect
    assign debug_forwardA_from_fwd_unit  = forwardA_to_ex; // Direct output of ForwardingUnit
    assign debug_forwardB_from_fwd_unit  = forwardB_to_ex; // Direct output of ForwardingUnit

endmodule

    // ... (localparams and existing wire declarations remain the same) ...
    // You already have most of the internal wires declared. We just need to assign them.
