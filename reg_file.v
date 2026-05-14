module reg_file (
    input         clk,
    input         we,          // write enable (from WB)
    input  [4:0]  rs1, rs2,   // read ports
    input  [4:0]  rd_w,        // write address
    input  [31:0] wd,          // write data
    output [31:0] rd1, rd2     // read data
);
    reg [31:0] regs [0:31];
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1)
            regs[i] = 32'b0;
    end

    // Write-then-read: WB writes on posedge, ID reads combinationally
    always @(posedge clk) begin
        if (we && rd_w != 5'b0)
            regs[rd_w] <= wd;
    end

    // Read (x0 always 0)
    assign rd1 = (rs1 == 5'b0) ? 32'b0 : regs[rs1];
    assign rd2 = (rs2 == 5'b0) ? 32'b0 : regs[rs2];
endmodule
