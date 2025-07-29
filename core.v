module Core #(
    parameter BOOT_ADDRESS = 32'h00000000
) (
    // Control signal
    input wire clk,
    // input wire halt,
    input wire rst_n,

    // Memory BUS
    // input  wire ack_i,
    output wire rd_en_o,
    output wire wr_en_i,
    // output wire [3:0]  byte_enable,
    input  wire [31:0] data_i,
    output wire [31:0] addr_o,
    output wire [31:0] data_o
);

//-----------//
// Declaração de sinais internos
//-----------//

// PC
reg [31:0] PC;
wire [31:0] PC_plus4;
wire [31:0] PC_next;
wire PC_write_enable;

// IR
reg [31:0] IR;
wire [6:0] opcode = IR[6:0];
wire [4:0] rd = IR[11:7];
wire [2:0] funct3 = IR[14:12];
wire [4:0] rs1 = IR[19:15];
wire [4:0] rs2 = IR[24:20];
wire [6:0] funct7 = IR[31:25];

// Registrador de dados de memória
reg [31:0] MDR;

// Registrador de ALUOut
reg [31:0] ALUOut;

// Saídas do register file
wire [31:0] RS1_data;
wire [31:0] RS2_data;

// Gerador de imediato
wire [31:0] imm_ext;

// ALU
wire [3:0] ALU_OP;
wire ALU_Z;
wire [31:0] ALU_in1;
wire [31:0] ALU_in2;
wire [31:0] ALU_result;

// Sinais da unidade de controle
wire pc_write;
wire ir_write;
wire pc_write_cond;
wire pc_source;
wire reg_write;
wire memory_read;
wire memory_to_reg;
wire memory_write;
wire [1:0] aluop;
wire [1:0] alu_src_a;
wire [1:0] alu_src_b;
wire is_immediate;
wire lorD;

//-----------//
// Instanciamento de módulos
//-----------//

// Unidade de controle

Control_Unit ctrl(
    .clk(clk),
    .rst_n(rst_n),
    .instruction_opcode(opcode),
    .pc_write(pc_write),
    .ir_write(ir_write),
    .pc_source(pc_source),
    .reg_write(reg_write),
    .memory_read(memory_read),
    .is_immediate(is_immediate),
    .memory_write(memory_write),
    .pc_write_cond(pc_write_cond),
    .lorD(lorD),
    .memory_to_reg(memory_to_reg),
    .aluop(aluop),
    .alu_src_a(alu_src_a),
    .alu_src_b(alu_src_b)
);

// Lógica do PC

assign PC_plus4 = PC + 32'd4;
wire [31:0] PC_sel = pc_source ? ALUOut : PC_plus4;
assign PC_write_enable = pc_write | (pc_write_cond & ALU_Z);
assign PC_next = PC_sel;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        PC <= BOOT_ADDRESS;
    end else if(PC_write_enable) begin
        PC <= PC_next;
    end
end

// IR, MDR e ALUOut

always @(posedge clk) begin
    if(ir_write) begin
        IR <= data_i;
    end
end
always @(posedge clk) begin
    if(memory_read || memory_write) begin
        MDR <= data_i;
    end
end
always @(posedge clk) begin
    if(alu_src_a != 2'b00 || alu_src_b != 2'b00) begin
        ALUOut <= ALU_result;
    end
end

// Register file

reg [31:0] reg_write_data;
reg reg_write_enable;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        reg_write_enable <= 0;
        reg_write_data <= 0;
    end else begin
        if(memory_to_reg)
            reg_write_data <= MDR;
        else
            reg_write_data <= ALU_result;

        reg_write_enable <= reg_write; // assume reg_write vem do Control Unit com 1 ciclo de atraso ou sincronizado
    end
end

Registers regfile(
    .clk(clk),
    .wr_en_i(reg_write_enable),
    .RS1_ADDR_i(rs1),
    .RS2_ADDR_i(rs2),
    .RD_ADDR_i(rd),
    .data_i(reg_write_data),
    .RS1_data_o(RS1_data),
    .RS2_data_o(RS2_data)
);


// Gerador de imediato

Immediate_Generator imm_gen(
    .instr_i(IR),
    .imm_o(imm_ext)
);

// ALU Control

ALU_Control aluctrl(
    .is_immediate_i(is_immediate),
    .ALU_CO_i (aluop),
    .FUNC7_i (funct7),
    .FUNC3_i (funct3),
    .ALU_OP_o (ALU_OP)
);

// MUX do ALU

assign ALU_in1 =  (alu_src_a == 2'b00) ? PC
                : (alu_src_a == 2'b01) ? RS1_data
                : 32'b0;
assign ALU_in2 =  (alu_src_b == 2'b00) ? RS2_data
                : (alu_src_b == 2'b01) ? 32'd4
                : imm_ext;

// ALU

Alu alu(
    .ALU_OP_i (ALU_OP),
    .ALU_RS1_i (ALU_in1),
    .ALU_RS2_i (ALU_in2),
    .ALU_RD_o (ALU_result),
    .ALU_ZR_o (ALU_Z)
);

// Saídas de memória

assign rd_en_o = memory_read;
assign wr_en_i = memory_write;
assign addr_o = lorD ? ALUOut : PC;
assign data_o = RS2_data;

endmodule
