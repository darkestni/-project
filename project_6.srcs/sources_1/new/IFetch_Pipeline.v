module IFetch (
    input clk,
    input reset,

    // --- ���Կ��Ƶ�Ԫ/ð�ռ�ⵥԪ�Ŀ����ź� ---
    input        branch,      // PC��Դѡ���ź�: 0 = PC+4, 1 = ��ת
    input [31:0] target_pc_in_if,   // ��ת��Ŀ��PC��ַ
    input        stall_if,         


    input        debugMode,
    input [31:0] testScenario,      

    // --- to IF/ID Pipe Reg ---
    output reg [31:0] instruction_to_ifid, // ��ȡ����ָ��
    output reg [31:0] pc_current_to_ifid,  // ��ǰPC
    output reg [31:0] pc_plus_4_to_ifid    // ��ǰPC + 4
);

    parameter RESET_PC = 32'h00000000;


    reg [31:0] pc_reg;                  
    wire [31:0] pc_plus_4_calc;        
    wire [31:0] next_pc_for_pc_reg;     


    wire [31:0] bram_instruction_data; // read from Instruction Memory

    prgrom urom(
        .clka(clk),         
        .addra(pc_reg[15:2]),    
        .douta(bram_instruction_data) 
    );


    assign pc_plus_4_calc = pc_reg + 4;
    assign next_pc_for_pc_reg = branch ? target_pc_in_if : pc_plus_4_calc;

    // PC�Ĵ��������߼�
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_reg <= RESET_PC;
        end else if (!stall_if) begin // ���IF�׶�û�б���ͣ
            pc_reg <= next_pc_for_pc_reg;
        end
        //����Data Hazardʱ��stall = 1, IF��ͣ
        //pc_reg ���ֲ���, �൱�����»�ȡ��ǰָ��
    end

    // Instruction and PC output
    always @(*) begin
        if (reset) begin 
            instruction_to_ifid = 32'h00000013; // NOP 
            pc_current_to_ifid  = RESET_PC;     
            pc_plus_4_to_ifid   = RESET_PC + 4;
        end
        //Debug Mode
        else begin
            if (debugMode && testScenario != 32'd0) begin
                instruction_to_ifid = testScenario; 
            end
            else begin
                instruction_to_ifid = bram_instruction_data;
            end
            pc_current_to_ifid  = pc_reg;           // �����ǰPCֵ
            pc_plus_4_to_ifid   = pc_plus_4_calc;   // ���PC+4��ֵ
        end
    end

endmodule