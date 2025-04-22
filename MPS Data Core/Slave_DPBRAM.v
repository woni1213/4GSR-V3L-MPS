`timescale 1ns / 1ps

module Slave_DPBRAM
(
	input i_clk,

    // Write Only
	input [7:0] i_slave_w_ram_addr,
    input i_slave_w_ram_ce,
    input [31:0] i_slave_w_ram_din,

    // Read Only
    input [7:0] i_slave_r_ram_addr,
    input i_slave_r_ram_ce,
    output reg [31:0] o_slave_r_ram_dout
);
 
(* RAM_STYLE = "BLOCK"*) reg [31:0] ram[0:255];

always @(posedge i_clk) 
begin
    ram[i_slave_w_ram_addr] <= (i_slave_w_ram_ce) ? i_slave_w_ram_din : ram[i_slave_w_ram_addr];
end

always @(posedge i_clk) 
begin
    o_slave_r_ram_dout <= (i_slave_r_ram_ce) ? ram[i_slave_r_ram_addr] : o_slave_r_ram_dout;
end

endmodule