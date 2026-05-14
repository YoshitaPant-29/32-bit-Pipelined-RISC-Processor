// Pure combinational - no clock needed
module forwarding_unit (
    input  [4:0] id_ex_rs1, id_ex_rs2,    // sources in EX stage
    input  [4:0] ex_mem_rd,                 // dest in EX/MEM reg
    input        ex_mem_reg_write,
    input  [4:0] mem_wb_rd,                 // dest in MEM/WB reg
    input        mem_wb_reg_write,
    output reg [1:0] forward_a,             // 00=reg, 10=EX/MEM, 01=MEM/WB
    output reg [1:0] forward_b
);
    always @(*) begin
        // ForwardA
        if (ex_mem_reg_write && ex_mem_rd != 0 && ex_mem_rd == id_ex_rs1)
            forward_a = 2'b10;  // forward from EX/MEM
        else if (mem_wb_reg_write && mem_wb_rd != 0 && mem_wb_rd == id_ex_rs1)
            forward_a = 2'b01;  // forward from MEM/WB
        else
            forward_a = 2'b00;  // from register file

        // ForwardB
        if (ex_mem_reg_write && ex_mem_rd != 0 && ex_mem_rd == id_ex_rs2)
            forward_b = 2'b10;
        else if (mem_wb_reg_write && mem_wb_rd != 0 && mem_wb_rd == id_ex_rs2)
            forward_b = 2'b01;
        else
            forward_b = 2'b00;
    end
endmodule
