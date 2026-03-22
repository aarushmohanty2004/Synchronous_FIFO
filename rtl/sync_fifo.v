module sync_fifo #(
parameter integer DATA_WIDTH = 8,
parameter integer DEPTH = 16,
parameter integer ADDR_WIDTH = 4
) (
input wire clk,
input wire rst_n, // active-low synchronous reset
input wire wr_en,
input wire [DATA_WIDTH-1:0] wr_data,
output wire wr_full,
input wire rd_en,
output reg [DATA_WIDTH-1:0] rd_data,
output wire rd_empty,
output reg [ADDR_WIDTH:0] count
);


reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
reg [ADDR_WIDTH-1:0] wr_ptr;
reg [ADDR_WIDTH-1:0] rd_ptr;

assign rd_empty = (count==0);
assign wr_full = (count==DEPTH);


always @(posedge clk)
begin
	if(!rst_n)
	begin
		wr_ptr<=0;
		rd_ptr<=0;
		count<=0;
		rd_data<=0;
	end
	else begin
	if(wr_en && (!wr_full))				//write operation
		begin
			mem[wr_ptr] <= wr_data;
			wr_ptr <= wr_ptr + 1;
		end
	if(rd_en && (!rd_empty))				//read operation
		begin
			rd_data <= mem[rd_ptr];
			rd_ptr <= rd_ptr + 1;
		end	
	case ({wr_en && !wr_full, rd_en && !rd_empty}) //counter-update
        2'b10: count <= count + 1;  
        2'b01: count <= count - 1; 
        default: count <= count;
    endcase
	end
end

endmodule