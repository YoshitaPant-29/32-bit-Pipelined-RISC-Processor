`timescale 1ns/1ps
module tb_pipeline;
    reg clk, reset;

    // CPI measurement
    integer cycle_count;
    integer instr_committed;

    pipeline_top DUT (.clk(clk), .reset(reset));

    // Clock: 10ns period
    always #5 clk = ~clk;

    // Count instructions committed at WB stage
    // A valid WB commit = reg_write asserted with non-zero rd
    always @(posedge clk) begin
        if (!reset && DUT.mem_wb_reg_write && DUT.mem_wb_rd != 0)
            instr_committed = instr_committed + 1;
        cycle_count = cycle_count + 1;
    end

    initial begin
        $dumpfile("pipeline.vcd");
        $dumpvars(0, tb_pipeline);

        clk = 0; reset = 1;
        cycle_count = 0; instr_committed = 0;
        #15 reset = 0;

        // Run enough cycles to drain the pipeline
        #300;

        $display("========================================");
        $display(" Pipeline Simulation Summary");
        $display("========================================");
        $display(" Total cycles      : %0d", cycle_count);
        $display(" Instrs committed  : %0d", instr_committed);
        if (instr_committed > 0)
            $display(" CPI               : %0.2f",
                     $itor(cycle_count) / $itor(instr_committed));
        $display("========================================");
        $display(" Final register file state:");
        $display("  x1 = %0d", DUT.RF.regs[1]);
        $display("  x2 = %0d", DUT.RF.regs[2]);
        $display("  x3 = %0d", DUT.RF.regs[3]);
        $display("  x4 = %0d (should be 99 from LW)", DUT.RF.regs[4]);
        $display("  x5 = %0d", DUT.RF.regs[5]);
        $display("  x8 = %0d (branch target result)", DUT.RF.regs[8]);
        $display("  x6 = %0d (should be 0 - was flushed)", DUT.RF.regs[6]);
        $display("  x7 = %0d (should be 0 - was flushed)", DUT.RF.regs[7]);
        $display("========================================");
        $finish;
    end
endmodule
