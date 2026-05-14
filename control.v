module control (
    input  [6:0] opcode,
    output reg   reg_write,
    output reg   mem_read,
    output reg   mem_write,
    output reg   mem_to_reg,
    output reg   branch,
    output reg   alu_src,       // 0=reg, 1=imm
    output reg [3:0] alu_ctrl
);
    always @(*) begin
        reg_write  = 0; mem_read  = 0; mem_write = 0;
        mem_to_reg = 0; branch    = 0; alu_src   = 0;
        alu_ctrl   = 4'b0000;

        case (opcode)
            7'b0110011: begin // R-type (ADD, SUB, AND, OR)
                reg_write = 1; alu_ctrl = 4'b0000;
            end
            7'b0010011: begin // I-type (ADDI)
                reg_write = 1; alu_src = 1; alu_ctrl = 4'b0000;
            end
            7'b0000011: begin // LW
                reg_write = 1; mem_read = 1; mem_to_reg = 1;
                alu_src = 1; alu_ctrl = 4'b0000;
            end
            7'b0100011: begin // SW
                mem_write = 1; alu_src = 1; alu_ctrl = 4'b0000;
            end
            7'b1100011: begin // BEQ
                branch = 1; alu_ctrl = 4'b0001; // SUB to compare
            end
            default: ;
        endcase
    end
endmodule
