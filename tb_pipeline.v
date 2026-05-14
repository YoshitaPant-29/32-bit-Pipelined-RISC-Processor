`timescale 1ns/1ps
module tb_pipeline;
    reg clk, reset;

    integer cycle_count, instr_committed, stall_count;
    integer seq_start_cycle, seq_start_instr;

    pipeline_top DUT (.clk(clk), .reset(reset));
    always #5 clk = ~clk;

    // Count stalls: when pc_write is deasserted (pipeline frozen)
    always @(posedge clk) begin
        if (!reset) begin
            cycle_count = cycle_count + 1;
            if (!DUT.pc_write) stall_count = stall_count + 1;
            if (DUT.mem_wb_reg_write && DUT.mem_wb_rd != 0)
                instr_committed = instr_committed + 1;
        end
    end

    task print_stats;
        input [127:0] label;
        integer c, i;
        begin
            c = cycle_count - seq_start_cycle;
            i = instr_committed - seq_start_instr;
            $display("--- %s ---", label);
            $display("  Cycles     : %0d", c);
            $display("  Instrs     : %0d", i);
            if (i > 0) begin
                $display("  CPI        : %0.2f", $itor(c) / $itor(i));
                $display("  Throughput : %0.4f instrs/ns  (clk=10ns)",
                         $itor(i) / ($itor(c) * 10.0));
                $display("  Latency    : %0d cycles per instr (single instr = 5 + stalls)",
                         c / i);
            end
            seq_start_cycle = cycle_count;
            seq_start_instr = instr_committed;
        end
    endtask

    initial begin
        $dumpfile("pipeline.vcd"); $dumpvars(0, tb_pipeline);
        clk=0; reset=1;
        cycle_count=0; instr_committed=0; stall_count=0;
        seq_start_cycle=0; seq_start_instr=0;
        #15 reset=0;

        // Seq 1: ADD->ADD->ADD (forwarding, no stalls expected)
        #80; print_stats("SEQ1: ALU->ALU forwarding (ADD->ADD->ADD)");

        // Seq 2: LW->ADD (1 stall expected)
        #60; print_stats("SEQ2: Load-use hazard (LW->ADD)");

        // Seq 3: Branch flush (2 instrs flushed)
        #80; print_stats("SEQ3: Branch flush (BEQ taken)");

        // Full run summary
        $display("=== FULL RUN ===");
        $display("  Total cycles : %0d", cycle_count);
        $display("  Total instrs : %0d", instr_committed);
        $display("  Total stalls : %0d", stall_count);
        $display("  Overall CPI  : %0.2f",
                 $itor(cycle_count) / $itor(instr_committed));
        $display("  Reg x4 (LW result, expect 99): %0d", DUT.RF.regs[4]);
        $display("  Reg x6 (flushed, expect  0 ): %0d", DUT.RF.regs[6]);
        $finish;
    end
endmodule
