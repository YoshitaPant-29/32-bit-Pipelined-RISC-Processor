// Detects load-use and branch hazards
module hazard_unit (
    input        id_ex_mem_read,   // is EX-stage instr a load?
    input  [4:0] id_ex_rd,         // load destination
    input  [4:0] if_id_rs1,        // sources in ID stage
    input  [4:0] if_id_rs2,
    input        branch_taken,     // branch resolved in EX
    output reg   pc_write,         // 0 = freeze PC
    output reg   if_id_write,      // 0 = freeze IF/ID reg
    output reg   stall,            // insert bubble into ID/EX
    output reg   flush             // flush IF/ID and ID/EX on branch
);
    always @(*) begin
        // defaults: no stall, no flush
        pc_write    = 1;
        if_id_write = 1;
        stall       = 0;
        flush       = 0;

        // Load-use hazard: stall 1 cycle
        if (id_ex_mem_read &&
            (id_ex_rd == if_id_rs1 || id_ex_rd == if_id_rs2)) begin
            pc_write    = 0; // freeze PC
            if_id_write = 0; // freeze IF/ID
            stall       = 1; // bubble into ID/EX
        end

        // Branch flush (overrides stall if both trigger together)
        if (branch_taken) begin
            flush = 1;
        end
    end
endmodule
