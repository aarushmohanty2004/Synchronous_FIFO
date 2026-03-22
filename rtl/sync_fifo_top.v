module sync_fifo_top #(
parameter integer DATA_WIDTH = 8,
parameter integer DEPTH = 16,
parameter integer ADDR_WIDTH=$clog2(DEPTH)
) (
input wire clk,
input wire rst_n, // active-low synchronous reset
input wire wr_en,
input wire [DATA_WIDTH-1:0] wr_data,
output wire wr_full,
input wire rd_en,
output wire [DATA_WIDTH-1:0] rd_data,
output wire rd_empty,
output wire [ADDR_WIDTH:0] count
);

sync_fifo #(
.DEPTH(DEPTH),
.DATA_WIDTH(DATA_WIDTH),
.ADDR_WIDTH(ADDR_WIDTH)
) sync_1(
.clk(clk),
.rst_n(rst_n), // active-low synchronous reset
.wr_en(wr_en),
.wr_data(wr_data),
.wr_full(wr_full),
.rd_en(rd_en),
.rd_data(rd_data),
.rd_empty(rd_empty),
.count(count)
);

endmodule