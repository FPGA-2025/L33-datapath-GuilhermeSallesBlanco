module Registers (
    input  wire clk,
    input  wire wr_en_i, // Habilita escrita no registrador RD
    
    input  wire [4:0] RS1_ADDR_i, // Endereço do registrador de leitura RS1
    input  wire [4:0] RS2_ADDR_i, // Endereço do registrador de leitura RS2
    input  wire [4:0] RD_ADDR_i, // Endereço do registrador de escrita RD

    input  wire [31:0] data_i, // Dados a serem escritos no registrador RD
    output wire [31:0] RS1_data_o, // Dados lidos do registrador RS1
    output wire [31:0] RS2_data_o // Dados lidos do registrador RS2
);

// Leitura é assíncrona, ou seja, a saída reflete imediatamente qualquer mudança no endereço.
// Escrita é síncrona, ocorrendo apenas na borda de subida do clock quando wr_en_i estiver ativo.

reg [31:0] registers [0:31]; // Array de 32 registradores de 32 bits

always @(posedge clk) begin // Processo de escrita
    if(wr_en_i && RD_ADDR_i != 0) begin
        registers[RD_ADDR_i] <= data_i; // Escreve data_i no registrador RD
    end
end

// Processo de leitura

// if(RS1_ADDR_i != 0) begin
//     assign RS1_data_o = registers[RS1_ADDR_i]; // Lê o registrador RS1
// end else begin
//     assign RS1_data_o = 32'b0; // Se RS1_ADDR_i for 0, retorna 0
// end

// if(RS2_ADDR_i != 0) begin
//     assign RS2_data_o = registers[RS2_ADDR_i]; // Lê o registrador RS2
// end else begin
//     assign RS2_data_o = 32'b0; // Se RS2_ADDR_i for 0, retorna 0
// end

assign RS1_data_o = (RS1_ADDR_i != 0) ? registers[RS1_ADDR_i] : 32'b0; // Lê o registrador RS1
assign RS2_data_o = (RS2_ADDR_i != 0) ? registers[RS2_ADDR_i] : 32'b0; // Lê o registrador RS2

endmodule