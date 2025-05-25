module PipelineCPU (
    input clk,
    input reset,

    //for test (existing)
    output wire [31:0] x1,
    output wire [31:0] x2,
    output wire [31:0] x3,
    output wire [31:0] x4,
    output wire [31:0] x5,
    output wire [31:0] dbg_ifid_instruction,
    output wire [31:0] dbg_if_pc,
    output wire [31:0] dbg_ex_operand_a,
    output wire [31:0] dbg_ex_operand_b,
    output wire [4:0]  dbg_idex_rs1,
    output wire [4:0]  dbg_idex_rs2,
    output wire [31:0] dbg_ex_whether_jump,
    output wire [31:0] dbg_idex_jump_target,
    output wire [31:0] dbg_forward_a_b_ex, //左1是forwardA 左2是forwardB
    output wire [31:0] dbg_datahazard_detect_stall_pc_ifid_idexnop, //数码管左1是stall_if 左2是ifid_stall 左3是idex_nop
    output wire [31:0] dbg_clk_count, //时钟计数器
    input [3:0] debugMode, // Changed from single bit
    input [31:0] testScenario,
    input  [15:0] switch_in,
    output [15:0] led_out,
    output [31:0] seg_physical_out // Changed from 7-bit seg, 4-bit an
);
  localparam BUTTON_WIDTH = 3;
  localparam DIP_WIDTH = 16;
  localparam LED_WIDTH = 16;

    // Internal wires, some renamed for clarity or to match new port names
    wire [1:0] forwardA_to_ex; // Actual forwarding signal from ForwardingUnit to EX
    wire [1:0] forwardB_to_ex; // Actual forwarding signal from ForwardingUnit to EX
    wire branch; // branch_or_jump_to_if from EX stage
    wire [31:0] target_pc_in_if;
    wire stall_if;
    wire [31:0] instruction_to_ifid;
    wire [31:0] pc_current_to_ifid;
    // wire [31:0] pc_plus_4_to_ifid; // Not used by IFID reg in provided code
    wire [1:0] forwardA_from_idex_unused; // Declared in original, but not driven by active FwdUnit. Kept for reference if needed.
    wire [1:0] forwardB_from_idex_unused; // Declared in original, but not driven by active FwdUnit. Kept for reference if needed.
    wire idex_nop;

    wire [31:0] alu_result_to_wb;
    wire [4:0]  rd_addr_to_wb;
    wire final_RegWrite_ctrl_to_wb;
    wire MemToReg_ctrl_to_wb;
    wire [31:0] alu_result_to_mem;
    wire [31:0] branch_target_addr_to_mem; // From EXMEM reg, seems unused later
    wire [31:0] rdata2_for_store_to_mem;
    wire [4:0]  rd_addr_to_mem;
    // wire [31:0] pc_to_mem; // Not used by EXMEM reg in provided code
    // wire [31:0] pc_plus_4_to_mem; // Not used by EXMEM reg in provided code
    wire final_RegWrite_ctrl; // From EXMEM reg
    wire MemRead_ctrl_to_mem;
    wire MemWrite_ctrl_to_mem;
    wire IORead_ctrl_to_mem;
    wire IOWrite_ctrl_to_mem;
    wire MemToReg_ctrl_to_mem;
    wire [31:0] data_read_memwb_to_wb;

    // IFetch Stage
    IFetch u_ifetch (
        .clk(clk),
        .reset(reset),
        .branch(branch),
        .target_pc_in_if(target_pc_in_if),
        .stall_if(stall_if),
        .debugMode(debugMode[0]), // Assuming debugMode[0] controls IFetch's debugMode
        .testScenario(testScenario),
        .bram_instruction_data(instruction_to_ifid),
        .pc_current_to_ifid(pc_current_to_ifid)
    );

    // IF/ID Pipeline Register
    wire ifid_stall;
    wire ifid_flush_ifid;
    wire [31:0] instruction_to_id;
    wire [31:0] pc_current_to_id;
    assign ifid_flush_ifid = branch; // Flush if branch taken

    IFID_PipelineRegister u_ifid_reg (
        .clk(clk),
        .reset(reset),
        .enable_write(!ifid_stall),
        .flush_ifid(ifid_flush_ifid),
        .instruction_from_if(instruction_to_ifid),
        .pc_current_from_if(pc_current_to_ifid),
        .instruction_to_id(instruction_to_id),
        .pc_current_to_id(pc_current_to_id)
    );

    // ID Stage (Instruction Decode)
    wire [4:0]write_addr_from_wb;
    wire [31:0]write_data_from_wb;
    wire reg_write_enable_from_wb; // Added, as it's an input to ID stage
    wire [31:0] rdata1_to_ex;
    wire [31:0] rdata2_to_ex;
    wire [31:0] imm32_to_ex;
    wire [4:0] rd_addr_from_id; // Renamed from rd_addr_to_ex for clarity
    wire [4:0] rs1_addr_from_id; // Renamed from rs1_addr_to_ex for clarity
    wire [4:0] rs2_addr_from_id; // Renamed from rs2_addr_to_ex for clarity
    wire [31:0] pc_to_ex;
    wire regWrite_ctrl_to_ex;
    wire ALUSrc_ctrl_to_ex;
    wire [3:0] ALUOp_ctrl_to_ex;
    wire branch_ctrl_to_ex;
    wire jump_ctrl_to_ex;
    wire isLoad_ctrl_to_ex;
    wire isStore_ctrl_to_ex;
    wire isEcall_ctrl_to_ex; // Output from ID, to IDEX
    wire [1:0] ecall_type_to_ex; // Output from ID, to IDEX (used by IDEX reg)
    wire [2:0] funct3_from_id;
    wire [6:0] funct7_from_id;

    InstructionDecode_ID_Stage u_id_stage (
        .clk(clk),
        .reset(reset),
        .instruction_ifid(instruction_to_id),
        .pc_ifid(pc_current_to_id),
        .reg_write_enable_from_wb(reg_write_enable_from_wb),
        .write_addr_from_wb(write_addr_from_wb),
        .write_data_from_wb(write_data_from_wb),
        .x1(x1), .x2(x2), .x3(x3), .x4(x4), .x5(x5), // Test outputs
        .rdata1_to_ex(rdata1_to_ex),
        .rdata2_to_ex(rdata2_to_ex),
        .imm32_to_ex(imm32_to_ex),
        .rd_addr_to_ex(rd_addr_from_id),
        .rs1_addr_to_ex(rs1_addr_from_id),
        .rs2_addr_to_ex(rs2_addr_from_id),
        .pc_to_ex(pc_to_ex),
        .regWrite_ctrl_to_ex(regWrite_ctrl_to_ex),
        .ALUSrc_ctrl_to_ex(ALUSrc_ctrl_to_ex),
        .ALUOp_ctrl_to_ex(ALUOp_ctrl_to_ex),
        .branch_ctrl_to_ex(branch_ctrl_to_ex),
        .jump_ctrl_to_ex(jump_ctrl_to_ex),
        .isLoad_ctrl_to_ex(isLoad_ctrl_to_ex),
        .isStore_ctrl_to_ex(isStore_ctrl_to_ex),
        .funct3_w(funct3_from_id),
        .funct7_w(funct7_from_id)
        // .isEcall_ctrl_to_ex(isEcall_ctrl_to_ex), // Assuming ID stage generates this
        // .ecall_type_to_ex(ecall_type_to_ex)   // Assuming ID stage generates this
    );

    // ID/EX Pipeline Register
    wire idex_enable_write = 1'b1; // Placeholder, should be controlled by hazard logic if not always enabled
    wire [2:0] funct3_to_ex;
    wire [6:0] funct7_to_ex;
    wire [31:0] rdata1_idex_to_ex;
    wire [31:0] rdata2_idex_to_ex;
    wire [31:0] imm32_idex_to_ex;
    wire [4:0]  rd_addr_idex_to_ex;
    wire [4:0]  rs1_addr_idex_to_ex;
    wire [4:0]  rs2_addr_idex_to_ex;
    wire [31:0] pc_idex_to_ex;
    // wire [31:0] pc_plus_4_idex_to_ex; // Not in IDEX reg in provided code
    wire regWrite_ctrl_idex_to_ex;
    wire ALUSrc_ctrl_idex_to_ex;
    wire [3:0] ALUOp_ctrl_idex_to_ex;
    wire branch_ctrl_idex_to_ex;
    wire jump_ctrl_idex_to_ex;
    wire isLoad_ctrl_idex_to_ex;
    wire isStore_ctrl_idex_to_ex;
    wire isEcall_ctrl_idex_to_ex; // From IDEX reg to EX stage
    wire [1:0] ecall_type_idex_to_ex; // From IDEX reg to EX stage (renamed from ecall_type_to_ex)

    wire flush_idex;
    assign flush_idex = idex_nop || branch; // Flush if hazard detected or branch taken

    IDEX_PipelineRegister u_idex_reg (
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
        .ecall_type_from_id(ecall_type_to_ex), // Assuming this comes from ID stage
        .regWrite_ctrl_from_id(regWrite_ctrl_to_ex),
        .ALUSrc_ctrl_from_id(ALUSrc_ctrl_to_ex),
        .ALUOp_ctrl_from_id(ALUOp_ctrl_to_ex),
        .branch_ctrl_from_id(branch_ctrl_to_ex),
        .jump_ctrl_from_id(jump_ctrl_to_ex),
        .isLoad_ctrl_from_id(isLoad_ctrl_to_ex),
        .isStore_ctrl_from_id(isStore_ctrl_to_ex),
        .isEcall_ctrl_from_id(isEcall_ctrl_to_ex), // Assuming this comes from ID stage
        .funct3_from_id(funct3_from_id),
        .funct7_from_id(funct7_from_id),
        .rdata1_to_ex(rdata1_idex_to_ex),
        .rdata2_to_ex(rdata2_idex_to_ex),
        .imm32_to_ex(imm32_idex_to_ex),
        .rd_addr_to_ex(rd_addr_idex_to_ex),
        .rs1_addr_to_ex(rs1_addr_idex_to_ex),
        .rs2_addr_to_ex(rs2_addr_idex_to_ex),
        .pc_to_ex(pc_idex_to_ex),
        .ecall_type_to_ex(ecall_type_idex_to_ex),
        .regWrite_ctrl_to_ex(regWrite_ctrl_idex_to_ex),
        .ALUSrc_ctrl_to_ex(ALUSrc_ctrl_idex_to_ex),
        .ALUOp_ctrl_to_ex(ALUOp_ctrl_idex_to_ex),
        .branch_ctrl_to_ex(branch_ctrl_idex_to_ex),
        .jump_ctrl_to_ex(jump_ctrl_idex_to_ex),
        .isLoad_ctrl_to_ex(isLoad_ctrl_idex_to_ex),
        .isStore_ctrl_to_ex(isStore_ctrl_idex_to_ex),
        .isEcall_ctrl_to_ex(isEcall_ctrl_idex_to_ex),
        .funct3_to_ex(funct3_to_ex),
        .funct7_to_ex(funct7_to_ex)
    );

    // EX Stage (Execute)
    wire [31:0] alu_result_to_exmem;
    // wire branch_condition_met_to_exmem; // This is 'branch' signal
    // wire branch_target_addr_to_exmem; // This is 'target_pc_in_if'
    wire [31:0] rdata2_for_store_to_exmem;
    wire [4:0]  rd_addr_to_exmem;
    wire RegWrite_ctrl_to_exmem; // Renamed from final_RegWrite_ctrl_to_exmem for clarity
    wire MemRead_to_exmem;
    wire MemWrite_to_exmem;
    wire IORead_to_exmem;
    wire IOWrite_to_exmem;
    wire MemToReg_to_exmem;
    wire [31:0] ex_alu_operand_a_internal; // Internal wire for EX stage operand A
    wire [31:0] ex_alu_operand_b_internal; // Internal wire for EX stage operand B


    Execute_Stage_Wrapper u_exe (
        .clk(clk),
        .reset(reset),
        .funct3_from_idex(funct3_to_ex),
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
        .exmem_alu_result(alu_result_to_mem), // This is feedback for forwarding
        .alu_operand_a(ex_alu_operand_a_internal), // Connect to internal wire
        .alu_operand_b(ex_alu_operand_b_internal), // Connect to internal wire
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

    // EX/MEM Pipeline Register
    wire [2:0] funct3_to_mem; // From EX/MEM reg to MEM stage
    wire [6:0] funct7_to_mem; // From EX/MEM reg to MEM stage

    EXMEM_PipelineRegister u_exmem_reg (
        .clk(clk),
        .reset(reset),
        .enable_write(1'b1), // Placeholder
        .flush_exmem(1'b0),  // Placeholder
        .alu_result_from_ex(alu_result_to_exmem),
        .branch_target_addr_from_ex(target_pc_in_if), // EX calculates target_pc_in_if
        .rdata2_for_store_from_ex(rdata2_for_store_to_exmem),
        .rd_addr_from_ex(rd_addr_to_exmem),
        .final_RegWrite_ctrl_from_ex(RegWrite_ctrl_to_exmem),
        .MemRead_ctrl_from_ex(MemRead_to_exmem),
        .MemWrite_ctrl_from_ex(MemWrite_to_exmem),
        .IORead_ctrl_from_ex(IORead_to_exmem),
        .IOWrite_ctrl_from_ex(IOWrite_to_exmem),
        .MemToReg_ctrl_from_ex(MemToReg_to_exmem),
        .funct3_from_ex(funct3_to_ex), // Pass through funct3
        .funct7_from_ex(funct7_to_ex), // Pass through funct7
        .alu_result_to_mem(alu_result_to_mem),
        .branch_target_addr_to_mem(branch_target_addr_to_mem), // Output of EXMEM reg
        .rdata2_for_store_to_mem(rdata2_for_store_to_mem),
        .rd_addr_to_mem(rd_addr_to_mem),
        .final_RegWrite_ctrl_to_mem(final_RegWrite_ctrl),
        .funct3_to_mem(funct3_to_mem),
        .funct7_to_mem(funct7_to_mem),
        .MemRead_ctrl_to_mem(MemRead_ctrl_to_mem),
        .MemWrite_ctrl_to_mem(MemWrite_ctrl_to_mem),
        .IORead_ctrl_to_mem(IORead_ctrl_to_mem),
        .IOWrite_ctrl_to_mem(IOWrite_ctrl_to_mem),
        .MemToReg_ctrl_to_mem(MemToReg_ctrl_to_mem)
    );

    // MEM Stage (Memory Access or I/O)
    wire [31:0] data_read_from_dmem;
    wire [15:0] data_read_from_io;
    wire [31:0] data_read_to_wb;
    wire [31:0] addr_to_dmem_io;
    wire [31:0] data_to_write_to_dmem_io;
    wire led_write_enable_to_io;
    wire switch_read_enable_to_io;

    MemOrIO_Pipeline u_memorio (
        .MemRead_ctrl_from_exmem(MemRead_ctrl_to_mem),
        .MemWrite_ctrl_from_exmem(MemWrite_ctrl_to_mem),
        .IORead_ctrl_from_exmem(IORead_ctrl_to_mem),
        .IOWrite_ctrl_from_exmem(IOWrite_ctrl_to_mem),
        .alu_result_addr_from_exmem(alu_result_to_mem),
        .rdata2_for_store_from_exmem(rdata2_for_store_to_mem),
        .data_read_from_dmem(data_read_from_dmem),
        .data_read_from_io(data_read_from_io),
        .data_read_to_memwb(data_read_to_wb),
        .addr_to_dmem_io(addr_to_dmem_io),
        .data_to_write_to_dmem_io(data_to_write_to_dmem_io),
        .led_write_enable_to_io(led_write_enable_to_io),
        .switch_read_enable_to_io(switch_read_enable_to_io)
    );

    DMem u_DMem (
        .clk(clk),
        .MemRead(MemRead_ctrl_to_mem),
        .MemWrite(MemWrite_ctrl_to_mem),
        .mem_width(funct3_to_mem[1:0]),
        .sign_ext(~funct3_to_mem[2]),
        .addr(addr_to_dmem_io),
        .din(data_to_write_to_dmem_io),
        .dout(data_read_from_dmem)
    );

    wire  [BUTTON_WIDTH-1:0]  button_physical_in; // Placeholder, connect to actual buttons
    wire [31:0] seg_data_internal;   // Internal 7-bit segment data from IOModule
    wire [3:0] an_data_internal;    // Internal 4-bit anode select (NEEDS TO BE DRIVEN, e.g. from IOModule)
                                    // Currently an_data_internal is not driven by u_io instance.

    IOModule  #(
        .BUTTON_WIDTH(BUTTON_WIDTH),
        .DIP_WIDTH(DIP_WIDTH),
        .LED_WIDTH(LED_WIDTH)
    ) u_io (
        .clk(clk),
        .reset(reset),
        .io_address(addr_to_dmem_io),
        .io_writeData(data_to_write_to_dmem_io),
        .io_access_write_enable(IOWrite_ctrl_to_mem),
        .io_access_read_enable(IORead_ctrl_to_mem),
        .button_physical_in(button_physical_in),
        .switch_read_enable(switch_read_enable_to_io),
        .led_write_enable(led_write_enable_to_io),
        .dipSwitch_physical_in(switch_in),
        .io_readData_out(data_read_from_io),
        .led_physical_out(led_out),
        .seg_data_out(seg_data_internal) // Connect to internal 7-bit segment wire
        // Add .an_out(an_data_internal) or similar if IOModule provides anode signals
    );

    // MEM/WB Pipeline Register
    MEMWB_PipelineRegister u_memwb_reg (
        .clk(clk),
        .reset(reset),
        .alu_result_from_mem(alu_result_to_mem),
        .data_read_from_mem(data_read_to_wb),
        .rd_addr_from_mem(rd_addr_to_mem),
        .final_RegWrite_ctrl_from_mem(final_RegWrite_ctrl),
        .MemToReg_ctrl_from_mem(MemToReg_ctrl_to_mem),
        .alu_result_to_wb(alu_result_to_wb),
        .data_read_from_mem_to_wb(data_read_memwb_to_wb),
        .rd_addr_to_wb(rd_addr_to_wb),
        .final_RegWrite_ctrl_to_wb(final_RegWrite_ctrl_to_wb),
        .MemToReg_ctrl_to_wb(MemToReg_ctrl_to_wb)
    );

    // WB Stage (Write Back)
    WriteBack_Stage u_wb (
        .alu_result_from_memwb(alu_result_to_wb),
        .data_read_from_mem_from_memwb(data_read_memwb_to_wb),
        .rd_addr_from_memwb(rd_addr_to_wb),
        .final_RegWrite_ctrl_from_memwb(final_RegWrite_ctrl_to_wb),
        .MemToReg_ctrl_from_memwb(MemToReg_ctrl_to_wb),
        .write_data_to_regfile(write_data_from_wb),
        .write_addr_to_regfile(write_addr_from_wb),
        .reg_write_enable_to_regfile(reg_write_enable_from_wb)
    );

    // Hazard Detection and Forwarding Units
    DataHazardDetect u_data_hazard (
        .ex_isLoad(MemRead_to_exmem || IORead_to_exmem), // Corrected: use signals from EX stage output (before EXMEM reg)
                                                        // or signals from EXMEM reg if hazard detection is based on EX/MEM stage
                                                        // Original was MemRead_to_exmem, IORead_to_exmem which are outputs of EX stage
        .ex_rd_addr(rd_addr_to_exmem), // rd_addr from EX stage output
        .id_rs1_addr(rs1_addr_from_id),
        .id_rs2_addr(rs2_addr_from_id),
        .pc_stall(stall_if),
        .ifid_stall(ifid_stall),
        .idex_nop(idex_nop)
    );

    ForwardingUnit u_forwarding_unit (
        .id_ex_rs1(rs1_addr_idex_to_ex), // rs1 from ID/EX register
        .id_ex_rs2(rs2_addr_idex_to_ex), // rs2 from ID/EX register
        .ex_mem_rd(rd_addr_to_mem),      // rd from EX/MEM register
        .ex_mem_regWrite(final_RegWrite_ctrl), // RegWrite from EX/MEM register
        .mem_wb_rd(rd_addr_to_wb),       // rd from MEM/WB register
        .mem_wb_regWrite(final_RegWrite_ctrl_to_wb), // RegWrite from MEM/WB register
        .forwardA(forwardA_to_ex),
        .forwardB(forwardB_to_ex)
    );

    // Clock Counter
    wire [31:0] clk_count;
    ClockCount u_clk_count (
        .clk(clk),
        .reset(reset),
        .clk_count(clk_count)
    );


    // --- Assignments for Debug Outputs ---
    assign dbg_ifid_instruction = instruction_to_id;
    assign dbg_if_pc            = pc_current_to_id;
    assign dbg_ex_operand_a     = ex_alu_operand_a_internal; // From Execute_Stage_Wrapper output
    assign dbg_ex_operand_b     = ex_alu_operand_b_internal; // From Execute_Stage_Wrapper output
    assign dbg_idex_rs1         = rs1_addr_idex_to_ex;    // rs1_addr from ID/EX register output
    assign dbg_idex_rs2         = rs2_addr_idex_to_ex;    // rs2_addr from ID/EX register output

    // Assignment for dbg_ex_whether_jump: 1 if branch/jump is taken in EX stage
    assign dbg_ex_whether_jump  = {31'b0, branch};

    // Assignment for dbg_idex_jump_target: Potential jump target calculated using ID/EX values (e.g., PC + imm for JAL)
    // This is an example; actual calculation might depend on instruction type (JAL vs JALR)
    assign dbg_idex_jump_target = target_pc_in_if;

    // User-provided assignments (modified forwardA/B source based on analysis)
    // Using forwardA_to_ex and forwardB_to_ex as they are the actual forwarding signals from ForwardingUnit.
    // If forwardA_from_idex and forwardB_from_idex are intended, ensure they are correctly driven.
    assign dbg_forward_a_b_ex = {2'b0, forwardA_to_ex, 2'b0, forwardB_to_ex, 24'b0};
    assign dbg_datahazard_detect_stall_pc_ifid_idexnop = {3'b0,stall_if, 3'b0,ifid_stall, 3'b0,idex_nop, 20'b0};
    assign dbg_clk_count        = clk_count;

    // Assignment for 32-bit seg_physical_out
    // Assuming 7-bit segment data (seg_data_internal) and 4-bit anode select (an_data_internal)
    // an_data_internal needs to be driven (e.g., by IOModule if it has an anode output port).
    // Example: {padding, an_select[3:0], seg_data[6:0]}
    assign seg_physical_out     = seg_data_internal;

endmodule

