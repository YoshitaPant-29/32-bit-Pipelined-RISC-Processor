module data_mem (
    input         clk,
    input         we,
    input  [31:0] addr,
    input  [31:0] wd,
    output [31:0] rd
);
    reg [31:0] mem [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'b0;
        mem[0] = 32'd99; // preload for LW test
    end

    always @(posedge clk) begin
        if (we) mem[addr >> 2] <= wd;
    end

    assign rd = mem[addr >> 2];
endmodule
