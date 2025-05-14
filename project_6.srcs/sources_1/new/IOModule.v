`timescale 1ns / 1ps

module IOModule #(
    parameter BUTTON_WIDTH = 3,
    parameter DIP_WIDTH = 16,
    parameter LED_WIDTH = 16
)
(
    input clk,                      // ϵͳʱ��
    // input reset,                 // ��λ�źţ�������Ҫ���

    // --- �����ź� (ͨ������MemOrIO���Ч��MEM�׶�I/O������) ---
    input [31:0] io_address,        // I/O�豸��ַ (��MemOrIO���ݵ�ԭʼALU���)
    input [31:0] io_writeData,      // Ҫд��I/O�豸������ (��MemOrIO����)
    input        io_access_write_enable, // ͨ��I/Oд����ʹ�� (��MemOrIOȷ����I/OдʱΪ��)
    input        io_access_read_enable,  // ͨ��I/O������ʹ�� (��MemOrIOȷ����I/O��ʱΪ��)
    input  [BUTTON_WIDTH-1:0]  button_physical_in,    // ���԰�ť����������
    input led_write_enable,
    input switch_read_enable,

    // --- ʵ�ʵ�����I/O�˿� ---
    input [DIP_WIDTH-1:0]  dipSwitch_physical_in, // ����DIP���ص���������

    output reg [31:0] io_readData_out,  // ��ѡ��I/O�豸��ȡ������ (�ͻ�MemOrIO)
    output reg [LED_WIDTH-1:0]  led_physical_out, // �����8λLED���е������ź�
    output reg [6:0]  seg_physical_out, // ������߶�����ܶ���������ź� (a�Cg)
    output reg [3:0]  an_physical_out   // ������߶������λѡ�������ź�
);


    // I/O�豸���Ե�ַӳ��
    // ��Щ��ַӦ��CPU�����ΪI/O�豸�滮�ĵ�ַ��ȫһ��
    localparam DIP_ADDR    = 32'hFFFF0000;
    localparam BUTTON_ADDR = 32'hFFFF0004;
    localparam LED_ADDR    = 32'hFFFF0008;
    localparam SEG_ADDR    = 32'hFFFF000C;

    // �߶�����ܱ��� (0-9)
    reg [6:0] seg_codes [0:9];
    initial begin
        // ����������ܱ���ʾ�� (�͵�ƽ��Ч)
        seg_codes[0] = 7'b1000000; // 0
        seg_codes[1] = 7'b1111001; // 1
        seg_codes[2] = 7'b0100100; // 2
        seg_codes[3] = 7'b0110000; // 3
        seg_codes[4] = 7'b0011001; // 4
        seg_codes[5] = 7'b0010010; // 5
        seg_codes[6] = 7'b0000010; // 6
        seg_codes[7] = 7'b1111000; // 7
        seg_codes[8] = 7'b0000000; // 8
        seg_codes[9] = 7'b0010000; // 9
    end

    // I/O������ (����߼�)
    // �� io_access_read_enable ��Чʱ������ io_address �������ĸ��豸��ȡ����
    always @(*) begin
        io_readData_out = 32'd0; // Ĭ���޶����ݻ���Ч��ȡ
        if (io_access_read_enable) begin
            if (io_address == DIP_ADDR) begin
                io_readData_out = {{(32-DIP_WIDTH){1'b0}}, dipSwitch_physical_in};
            end else if (io_address == BUTTON_ADDR && switch_read_enable) begin
                io_readData_out ={{(32-BUTTON_WIDTH){1'b0}}, dipSwitch_physical_in};
            end
        end
    end

    // I/Oд���� (ͬ���߼�)
    // �� io_access_write_enable ��Чʱ������ io_address �������ĸ��豸д������
    always @(posedge clk) begin
        // �����Ҫ��λLED������ܵ�״̬���������������reset�߼�
        // if (reset) begin
        //    led_physical_out <= 8'd0;
        //    seg_physical_out <= 7'b1111111; // ���磺������ȫ��
        //    an_physical_out  <= 4'b1111;    // ���磺ȫ��ѡͨ
        // end else
        if (io_access_write_enable) begin
            case (io_address)
                LED_ADDR:  if (led_write_enable) led_physical_out <= io_writeData[LED_WIDTH-1:0];
                SEG_ADDR: begin
                    // ���� io_writeData[3:0] ��Ҫ��ʾ������ (0-9)
                    // ���� io_writeData[7:4] ����λѡ an (�����Ҫ�����ӵĿ���)
                    // �����Ϊֻ��ʾһλ�����̶�λѡ
                    if (io_writeData[3:0] < 10) begin // ��������Ƿ���0-9��Χ��
                        seg_physical_out <= seg_codes[io_writeData[3:0]];
                    end else begin
                        // ������Ч���֣�������ʾ�հס�����ָʾ���򱣳���һ����Ч״̬
                        seg_physical_out <= 7'b1111111; // ���磺��ʾ�հ� (������)
                    end
                    // �����λѡ�߼�
                    // ����ǵ�������ܣ����Թ̶�һ��λѡ������ѡ�е�һ����
                    an_physical_out  <= 4'b1110; // ����ʹ�ܵ�һ������� (AN0�͵�ƽ��Ч)
                    // �����Ҫ���� io_writeData ��ĳ��λ��ѡ���ĸ�����ܣ���������������߼�
                    // ����: an_physical_out <= ~io_writeData[7:4]; (����writeData�ĸ�λ����λѡ)
                    // ����Ƕ�̬ɨ�裬�˴��� an_physical_out �� seg_physical_out �ĸ��»�����ӣ�
                    // ͨ����Ҫһ��������ɨ����������ڸ���Ƶ�ʵ�ʱ���¸��¡�
                end
                // default: no operation for other addresses within I/O space
            endcase
        // } else { // �� io_access_write_enable Ϊ��ʱ������ѡ�񱣳������Ĭ��ֵ
            // �����ϣ���ڷ�д���ڸı�LED/�����״̬�����else�����ʡ�ԣ��Ĵ����ᱣ��ֵ
        // }
        end
    end

endmodule
