module ALU_Control (
    input wire is_immediate_i,
    input wire [1:0] ALU_CO_i,
    input wire [6:0] FUNC7_i,
    input wire [2:0] FUNC3_i,
    output reg [3:0] ALU_OP_o
);

// Definição dos opcodes da ALU
localparam AND             = 4'b0000; 
localparam OR              = 4'b0001;
localparam SUM             = 4'b0010;
localparam SUB             = 4'b1010;
localparam GREATER_EQUAL   = 4'b1100;
localparam GREATER_EQUAL_U = 4'b1101;
localparam SLT             = 4'b1110;
localparam SLT_U           = 4'b1111;
localparam SHIFT_LEFT      = 4'b0100;
localparam SHIFT_RIGHT     = 4'b0101;
localparam SHIFT_RIGHT_A   = 4'b0111;
localparam XOR             = 4'b1000;
localparam NOR             = 4'b1001;
localparam EQUAL           = 4'b0011;

// Definição dos tipos de comparação (funct3)
localparam FUNCT3_BEQ = 3'b000;
localparam FUNCT3_BNE = 3'b001;
localparam FUNCT3_SLT = 3'b100;
localparam FUNCT3_GREATER_EQUAL = 3'b101;
localparam FUNCT3_SLT_U = 3'b110;
localparam FUNCT3_GREATER_EQUAL_U = 3'b111;

// Identificar qual grupo a instrução pertence
// Escolher qual operação a ALU deve realizar
always @(*) begin
    case(ALU_CO_i)
        2'b00: begin // LOAD/STORE, só faz ADD
            ALU_OP_o = SUM;
        end
        2'b01: begin // BRANCH, faz algum tipo de comparação definida pelo campo funct3
            case(FUNC3_i)
                FUNCT3_BEQ : ALU_OP_o = SUB;
                FUNCT3_BNE : ALU_OP_o = EQUAL;
                FUNCT3_SLT: ALU_OP_o = GREATER_EQUAL;
                FUNCT3_GREATER_EQUAL: ALU_OP_o = SLT;
                FUNCT3_SLT_U: ALU_OP_o = GREATER_EQUAL_U;
                FUNCT3_GREATER_EQUAL_U: ALU_OP_o = SLT_U;
                default: ALU_OP_o = SUB; // Caso não seja nenhum dos tipos esperados
            endcase
        end
        2'b10: begin // ALU, faz alguma operação definida pelo campo funct3 e funct7
            case(FUNC3_i) // Começamos comparando o funct3, pois aparece primeiro, e já elimina muitas opções
                3'b000: begin // ADD ou SUB
                    if(!is_immediate_i) begin
                        if(FUNC7_i == 7'b0100000) begin // SUB
                            ALU_OP_o = SUB;
                        end else begin // ADD
                            ALU_OP_o = SUM;
                        end
                    end else begin // Se for imediato, só pode ser ADD
                        ALU_OP_o = SUM;
                    end
                end
                3'b111: begin // AND
                    ALU_OP_o = AND;
                end
                3'b110: begin // OR
                    ALU_OP_o = OR;
                end
                3'b100: begin // XOR
                    ALU_OP_o = XOR;
                end
                3'b001: begin // Shift Left Lógico
                    ALU_OP_o = SHIFT_LEFT;
                end
                3'b101: begin // Shift Right Lógico ou Aritmético
                    if(FUNC7_i == 7'b0100000) begin // Shift Right Aritmético
                        ALU_OP_o = SHIFT_RIGHT_A;
                    end else begin // Shift Right Lógico
                        ALU_OP_o = SHIFT_RIGHT;
                    end
                end
                3'b010: begin
                    ALU_OP_o = SLT; // SLT
                end
                3'b011: begin
                    ALU_OP_o = SLT_U; // SLT Unsigned
                end
                default: ALU_OP_o = 4'bxxxx; // Caso não seja nenhum dos tipos esperados
            endcase
        end
    default: ALU_OP_o = 4'bxxxx; // Caso não seja nenhum dos tipos esperados
    endcase     
end

endmodule
