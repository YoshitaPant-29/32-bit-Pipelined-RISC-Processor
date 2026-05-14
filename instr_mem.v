module instr_mem (
    input  [31:0] pc,
    output [31:0] instr
);
    reg [31:0] mem [0:63];

    initial begin
        // -- Test sequence 1: ALU->ALU forwarding (no stall needed)
        // ADD x1, x0, x0   (x1 = 0)
        mem[0]  = 32'h00000033;
        // ADD x2, x1, x1   (RAW on x1 -> forwarded from EX/MEM)
        mem[1]  = 32'h00108133;
        // ADD x3, x2, x1   (RAW on x2 -> forwarded from EX/MEM, x1 from MEM/WB)
        mem[2]  = 32'h001100B3;

        // -- Test sequence 2: LW->ADD load-use (1 stall required)
        // LW  x4, 0(x0)    (load from address 0)
        mem[3]  = 32'h00002203;
        // ADD x5, x4, x1   (x4 not ready -> 1 stall inserted by hazard unit)
        mem[4]  = 32'h00120293;

        // -- Test sequence 3: Branch flush
        // BEQ x0, x0, +8   (always taken, skip 2 instrs)
        mem[5]  = 32'h00000463;
        // ADD x6, x0, x0   (flushed - should not commit)
        mem[6]  = 32'h00000333;
        // ADD x7, x0, x0   (flushed - should not commit)
        mem[7]  = 32'h00000333;
        // ADD x8, x1, x2   (branch target - should execute)
        mem[8]  = 32'h00208433;

        // NOP padding
        mem[9]  = 32'h00000013; // ADDI x0,x0,0
        mem[10] = 32'h00000013;
        mem[11] = 32'h00000013;
        mem[12] = 32'h00000013;
    end

    assign instr = mem[pc >> 2];
endmodule
