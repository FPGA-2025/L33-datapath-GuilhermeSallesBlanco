module Control_Unit (
    input wire clk,
    input wire rst_n,
    input wire [6:0] instruction_opcode,
    output reg pc_write,
    output reg ir_write,
    output reg pc_source,
    output reg reg_write,
    output reg memory_read,
    output reg is_immediate,
    output reg memory_write,
    output reg pc_write_cond,
    output reg lorD,
    output reg memory_to_reg,
    output reg [1:0] aluop,
    output reg [1:0] alu_src_a,
    output reg [1:0] alu_src_b
);

// machine states
localparam FETCH              = 4'b0000;
localparam DECODE             = 4'b0001;
localparam MEMADR             = 4'b0010;
localparam MEMREAD            = 4'b0011;
localparam MEMWB              = 4'b0100;
localparam MEMWRITE           = 4'b0101;
localparam EXECUTER           = 4'b0110;
localparam ALUWB              = 4'b0111;
localparam EXECUTEI           = 4'b1000;
localparam JAL                = 4'b1001;
localparam BRANCH             = 4'b1010;
localparam JALR               = 4'b1011;
localparam AUIPC              = 4'b1100;
localparam LUI                = 4'b1101;
localparam JALR_PC            = 4'b1110;

// Instruction Opcodes
localparam LW      = 7'b0000011;
localparam SW      = 7'b0100011;
localparam RTYPE   = 7'b0110011;
localparam ITYPE   = 7'b0010011;
localparam JALI    = 7'b1101111;
localparam BRANCHI = 7'b1100011;
localparam JALRI   = 7'b1100111;
localparam AUIPCI  = 7'b0010111;
localparam LUII    = 7'b0110111;

reg [3:0] estado, prox_estado;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        estado <= FETCH;
    end else begin
        estado <= prox_estado;
    end
end

always @(*) begin
    pc_write      = 0;
    ir_write      = 0;
    pc_source     = 0;
    reg_write     = 0;
    memory_read   = 0;
    is_immediate  = 0;
    memory_write  = 0;
    pc_write_cond = 0;
    lorD          = 0;
    memory_to_reg = 0;
    aluop         = 2'b00;
    alu_src_a     = 2'b00;
    alu_src_b     = 2'b00;

    case(estado)
        FETCH: begin
            memory_read = 1;
            alu_src_a = 2'b00;
            lorD = 0;
            ir_write = 1;
            alu_src_b = 2'b01;
            aluop = 2'b00;
            pc_write = 1;
            pc_source = 0;
            prox_estado = DECODE;
        end
        DECODE: begin
            alu_src_a = 2'b10;
            alu_src_b = 2'b10;
            aluop = 2'b00;
            case(instruction_opcode)
                LW: begin
                    prox_estado = MEMADR;
                end
                SW: begin
                    prox_estado = MEMADR;
                end
                RTYPE: begin
                    prox_estado = EXECUTER;
                end
                ITYPE: begin
                    prox_estado = EXECUTEI;
                end
                JALI: begin
                    prox_estado = JAL;
                end
                BRANCHI: begin
                    prox_estado = BRANCH;
                end
                JALRI: begin
                    prox_estado = JALR_PC;
                end
                AUIPCI: begin
                    prox_estado = AUIPC;
                end
                LUII: begin
                    prox_estado = LUI;
                end
            endcase
        end
        MEMADR: begin
            alu_src_a = 2'b01;
            alu_src_b = 2'b10;
            aluop = 2'b00;
            if(instruction_opcode == LW) begin
                prox_estado = MEMREAD;
            end else if(instruction_opcode == SW) begin
                prox_estado = MEMWRITE;
            end
        end
        MEMREAD: begin
            memory_read = 1;
            lorD = 1;
            prox_estado = MEMWB;
        end
        MEMWB: begin
            reg_write = 1;
            memory_to_reg = 1;
            prox_estado = FETCH;
        end
        MEMWRITE: begin
            memory_write = 1;
            lorD = 1;
            prox_estado = FETCH;
        end
        AUIPC: begin
            alu_src_a = 2'b10;
            alu_src_b = 2'b10;
            aluop = 2'b00;
            prox_estado = ALUWB;
        end
        ALUWB: begin
            reg_write = 1;
            memory_to_reg = 0;
            prox_estado = FETCH;
        end
        JAL: begin
            alu_src_a = 2'b10;
            alu_src_b = 2'b01;
            pc_write = 1;
            pc_source = 1;
            aluop = 2'b00;
            prox_estado = ALUWB;
        end
        EXECUTEI: begin
            alu_src_a = 2'b01;
            alu_src_b = 2'b10;
            aluop = 2'b10;
            is_immediate = 1;
            prox_estado = ALUWB;
        end
        EXECUTER: begin
            alu_src_a = 2'b01;
            alu_src_b = 2'b00;
            aluop = 2'b10;
            prox_estado = ALUWB;
        end
        LUI: begin
            alu_src_a = 2'b11;
            alu_src_b = 2'b10;
            aluop = 2'b00;
            prox_estado = ALUWB;
        end
        JALR_PC: begin
            alu_src_a = 2'b01;
            alu_src_b = 2'b10;
            aluop = 2'b00;
            prox_estado = JALR;
        end
        JALR: begin
            alu_src_a = 2'b10;
            alu_src_b = 2'b01;
            pc_write = 1;
            pc_source = 1;
            aluop = 2'b00;
            is_immediate = 1;
            prox_estado = ALUWB;
        end
        BRANCH: begin
            alu_src_a = 2'b01;
            alu_src_b = 2'b00;
            aluop = 2'b01;
            pc_write_cond = 1;
            pc_source = 1;
            prox_estado = FETCH;
        end
        default: begin
            prox_estado = FETCH;
        end
    endcase
end


endmodule
