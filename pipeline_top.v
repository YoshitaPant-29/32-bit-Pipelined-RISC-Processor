module pipeline_top (
    input clk,
    input reset
);
    // ---- IF stage wires ----
    reg  [31:0] PC;
    wire [31:0] instr_if;

    // ---- IF/ID pipeline register ----
    reg [31:0] if_id_pc, if_id_instr;

    // ---- ID stage wires ----
    wire [6:0]  opcode  = if_id_instr[6:0];
    wire [4:0]  rs1     = if_id_instr[19:15];
    wire [4:0]  rs2     = if_id_instr[24:20];
    wire [4:0]  rd_id   = if_id_instr[11:7];
    wire [31:0] imm     = {{20{if_id_instr[31]}}, if_id_instr[31:20]};
    wire [31:0] rd1, rd2;
    wire        reg_write_id, mem_read_id, mem_write_id;
    wire        mem_to_reg_id, branch_id, alu_src_id;
    wire [3:0]  alu_ctrl_id;

    // ---- ID/EX pipeline register ----
    reg [31:0] id_ex_pc, id_ex_rd1, id_ex_rd2, id_ex_imm;
    reg [4:0]  id_ex_rs1, id_ex_rs2, id_ex_rd;
    reg [3:0]  id_ex_alu_ctrl;
    reg        id_ex_reg_write, id_ex_mem_read, id_ex_mem_write;
    reg        id_ex_mem_to_reg, id_ex_branch, id_ex_alu_src;

    // ---- EX stage wires ----
    wire [1:0]  forward_a, forward_b;
    reg  [31:0] alu_a, alu_b_pre;
    wire [31:0] alu_b;
    wire [31:0] alu_result;
    wire        alu_zero;
    wire [31:0] branch_target;
    wire        branch_taken;

    // ---- EX/MEM pipeline register ----
    reg [31:0] ex_mem_alu_result, ex_mem_rd2, ex_mem_pc_branch;
    reg [4:0]  ex_mem_rd;
    reg        ex_mem_reg_write, ex_mem_mem_read, ex_mem_mem_write;
    reg        ex_mem_mem_to_reg, ex_mem_zero, ex_mem_branch;

    // ---- MEM stage wires ----
    wire [31:0] mem_rd;

    // ---- MEM/WB pipeline register ----
    reg [31:0] mem_wb_alu_result, mem_wb_mem_rd;
    reg [4:0]  mem_wb_rd;
    reg        mem_wb_reg_write, mem_wb_mem_to_reg;

    // ---- WB stage wires ----
    wire [31:0] wb_data;

    // ---- Hazard wires ----
    wire pc_write, if_id_write, stall, flush;

    // =========================================================
    // Submodule instantiations
    // =========================================================
    instr_mem IMEM (.pc(PC), .instr(instr_if));

    control CTRL (
        .opcode(opcode),
        .reg_write(reg_write_id), .mem_read(mem_read_id),
        .mem_write(mem_write_id), .mem_to_reg(mem_to_reg_id),
        .branch(branch_id), .alu_src(alu_src_id),
        .alu_ctrl(alu_ctrl_id)
    );

    reg_file RF (
        .clk(clk), .we(mem_wb_reg_write),
        .rs1(rs1), .rs2(rs2),
        .rd_w(mem_wb_rd), .wd(wb_data),
        .rd1(rd1), .rd2(rd2)
    );

    forwarding_unit FWD (
        .id_ex_rs1(id_ex_rs1), .id_ex_rs2(id_ex_rs2),
        .ex_mem_rd(ex_mem_rd), .ex_mem_reg_write(ex_mem_reg_write),
        .mem_wb_rd(mem_wb_rd), .mem_wb_reg_write(mem_wb_reg_write),
        .forward_a(forward_a), .forward_b(forward_b)
    );

    hazard_unit HZU (
        .id_ex_mem_read(id_ex_mem_read), .id_ex_rd(id_ex_rd),
        .if_id_rs1(rs1), .if_id_rs2(rs2),
        .branch_taken(branch_taken),
        .pc_write(pc_write), .if_id_write(if_id_write),
        .stall(stall), .flush(flush)
    );

    alu ALU (.a(alu_a), .b(alu_b), .alu_ctrl(id_ex_alu_ctrl),
             .result(alu_result), .zero(alu_zero));

    data_mem DMEM (
        .clk(clk), .we(ex_mem_mem_write),
        .addr(ex_mem_alu_result), .wd(ex_mem_rd2),
        .rd(mem_rd)
    );

    // =========================================================
    // Forwarding muxes (EX stage)
    // =========================================================
    always @(*) begin
        case (forward_a)
            2'b10:   alu_a = ex_mem_alu_result;
            2'b01:   alu_a = wb_data;
            default: alu_a = id_ex_rd1;
        endcase
        case (forward_b)
            2'b10:   alu_b_pre = ex_mem_alu_result;
            2'b01:   alu_b_pre = wb_data;
            default: alu_b_pre = id_ex_rd2;
        endcase
    end

    assign alu_b        = id_ex_alu_src ? id_ex_imm : alu_b_pre;
    assign branch_target= id_ex_pc + (id_ex_imm << 1);
    assign branch_taken = id_ex_branch & alu_zero;
    assign wb_data      = mem_wb_mem_to_reg ? mem_wb_mem_rd : mem_wb_alu_result;

    // =========================================================
    // Pipeline registers (clocked)
    // =========================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            PC <= 0;
            // zero all pipeline registers
            if_id_pc <= 0; if_id_instr <= 0;
            id_ex_reg_write <= 0; id_ex_mem_read <= 0;
            id_ex_mem_write <= 0; id_ex_branch <= 0;
            ex_mem_reg_write <= 0; ex_mem_mem_write <= 0;
            ex_mem_branch <= 0; mem_wb_reg_write <= 0;
        end else begin
            // ---- IF ----
            if (pc_write) begin
                PC <= branch_taken ? branch_target : PC + 4;
            end

            // ---- IF/ID ----
            if (if_id_write) begin
                if_id_pc    <= PC;
                if_id_instr <= (flush) ? 32'h00000013 : instr_if; // flush=NOP
            end

            // ---- ID/EX ----
            if (stall || flush) begin
                // Insert bubble
                id_ex_reg_write  <= 0; id_ex_mem_read  <= 0;
                id_ex_mem_write  <= 0; id_ex_branch    <= 0;
                id_ex_mem_to_reg <= 0; id_ex_alu_src   <= 0;
                id_ex_rd <= 0; id_ex_rs1 <= 0; id_ex_rs2 <= 0;
            end else begin
                id_ex_pc        <= if_id_pc;
                id_ex_rd1       <= rd1;
                id_ex_rd2       <= rd2;
                id_ex_imm       <= imm;
                id_ex_rs1       <= rs1;
                id_ex_rs2       <= rs2;
                id_ex_rd        <= rd_id;
                id_ex_alu_ctrl  <= alu_ctrl_id;
                id_ex_reg_write <= reg_write_id;
                id_ex_mem_read  <= mem_read_id;
                id_ex_mem_write <= mem_write_id;
                id_ex_mem_to_reg<= mem_to_reg_id;
                id_ex_branch    <= branch_id;
                id_ex_alu_src   <= alu_src_id;
            end

            // ---- EX/MEM ----
            ex_mem_alu_result <= alu_result;
            ex_mem_rd2        <= alu_b_pre;
            ex_mem_rd         <= id_ex_rd;
            ex_mem_reg_write  <= id_ex_reg_write;
            ex_mem_mem_read   <= id_ex_mem_read;
            ex_mem_mem_write  <= id_ex_mem_write;
            ex_mem_mem_to_reg <= id_ex_mem_to_reg;
            ex_mem_zero       <= alu_zero;
            ex_mem_branch     <= id_ex_branch;

            // ---- MEM/WB ----
            mem_wb_alu_result <= ex_mem_alu_result;
            mem_wb_mem_rd     <= mem_rd;
            mem_wb_rd         <= ex_mem_rd;
            mem_wb_reg_write  <= ex_mem_reg_write;
            mem_wb_mem_to_reg <= ex_mem_mem_to_reg;
        end
    end
endmodule
