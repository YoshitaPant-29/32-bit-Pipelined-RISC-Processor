# 32-bit-Pipelined-RISC-Processor

Designed a 32-bit 5-stage pipelined RISC-V processor in Verilog with IF, ID, EX, MEM, and WB pipeline stages.

Developed RTL modules for the ALU, register file, control unit, instruction/data memory, forwarding unit, and hazard detection unit.

Implemented EX/MEM-to-EX and MEM/WB-to-EX forwarding, load-use stalling, and branch flush logic to handle pipeline hazards.

Built a verification environment that measured 35 committed instructions, 100 total cycles, 1 stall cycle, CPI of 2.86, and throughput of 0.035 instr/ns; synthesized and tested the design on a Nexys 4 DDR FPGA board.
