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
    output wire wr_en_o,
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
reg [31:0] PC_OLD;
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

assign PC_plus4 = ALU_result;
wire [31:0] PC_sel = pc_source ? ALUOut : ALU_result;
assign PC_write_enable = pc_write | (pc_write_cond & ALU_Z);
assign PC_next = PC_sel;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        PC <= BOOT_ADDRESS;
    end else if(PC_write_enable) begin
        PC <= PC_sel;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(ir_write) begin
        PC_OLD <= PC;
    end
end

// IR, MDR e ALUOut

always @(posedge clk) begin
    if(ir_write) begin
        IR <= data_i;
    end
end
always @(posedge clk) begin
        MDR <= data_i;
end
always @(posedge clk) begin
    ALUOut <= ALU_result;
end

// Register file

wire [31:0] reg_write_data = memory_to_reg ? MDR : ALUOut;;

Registers regfile(
    .clk(clk),
    .wr_en_i(reg_write),
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
                : (alu_src_a == 2'b10) ? PC_OLD
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
assign wr_en_o = memory_write;
wire [31:0] pc_MUX;
assign pc_MUX = (lorD == 1'b0) ? PC : ALUOut;
assign addr_o = pc_MUX;
assign data_o = RS2_data;

// Saídas para debugging (não estão sendo utilizadas atualmente)

// always @(posedge clk) begin
//     if (memory_write) begin
//         $display("Escrevendo na memória no endereco %h, dado %h, ciclo %d", addr_o, data_o, $time);
//     end
// end

// always @(posedge clk) begin
//     if (ir_write) begin
//         $display("Instr: %h, Imediato: %d, ciclo: %d", IR, imm_ext, $time);
//     end
// end

// always @(posedge clk) begin
//     if(memory_write) begin
//         $display("ALUOut: %d, endereco escrito: %h, ciclo: %d", ALUOut, addr_o, $time);
//     end
// end

// always @(posedge clk) begin
//     $display("Ciclo %d: PC=%h, lorD=%b, mem_read=%b, mem_write=%b, ALUOut=%h, addr_o=%h, RS2_data=%h", 
//         $time/10, PC, lorD, memory_read, memory_write, ALUOut, addr_o, RS2_data);
// end

// always @(posedge clk) begin
//     $display("Registrador x5: %h", RS1_data); // ou RS2_data dependendo da origem
// end

endmodule
