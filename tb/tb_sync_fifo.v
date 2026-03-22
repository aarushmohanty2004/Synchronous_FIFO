`timescale 1ns/1ps

module tb_sync_fifo;

parameter DATA_WIDTH = 8; 			//parameters 
parameter DEPTH = 16;
parameter ADDR_WIDTH = 4;

reg clk, rst_n, wr_en, rd_en;			//dut parameters
reg [DATA_WIDTH-1:0] wr_data;

wire wr_full, rd_empty;
wire [DATA_WIDTH-1:0] rd_data;
wire [ADDR_WIDTH:0] count;

reg [DATA_WIDTH-1:0] model_mem [0:DEPTH-1];			// golden model parameters
integer model_wr_ptr, model_rd_ptr, model_count;
reg [DATA_WIDTH-1:0] model_rd_data;

integer cov_full;								// coverage counters
integer cov_empty;
integer cov_simul;
integer cov_overflow;
integer cov_underflow;

integer cycle;									// cycle counters

sync_fifo #(									// dut
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .wr_en(wr_en),
    .wr_data(wr_data),
    .wr_full(wr_full),
    .rd_en(rd_en),
    .rd_data(rd_data),
    .rd_empty(rd_empty),
    .count(count)
);

always #5 clk = ~clk;							// clock generation

always @(posedge clk) begin						// golden model
    if (!rst_n) begin
        model_wr_ptr <= 0;
        model_rd_ptr <= 0;
        model_count  <= 0;
        model_rd_data <= 0;
    end 
	else begin

        // WRITE
        if (wr_en && (model_count < DEPTH)) begin
            model_mem[model_wr_ptr] <= wr_data;
            model_wr_ptr <= model_wr_ptr + 1;
        end

        // READ
        if (rd_en && (model_count > 0)) begin
            model_rd_data <= model_mem[model_rd_ptr];
            model_rd_ptr <= model_rd_ptr + 1;
        end

        // COUNT UPDATE
        if (wr_en && !rd_en && (model_count < DEPTH))
            model_count <= model_count + 1;
        else if (rd_en && !wr_en && (model_count > 0))
            model_count <= model_count - 1;

        // COVERAGE
        if (model_count == DEPTH) cov_full = cov_full + 1;
        if (model_count == 0)     cov_empty = cov_empty + 1;
        if (wr_en && rd_en)       cov_simul = cov_simul + 1;
        if (wr_en && model_count == DEPTH) cov_overflow = cov_overflow + 1;
        if (rd_en && model_count == 0)     cov_underflow = cov_underflow + 1;

    end
end

// =====================================================
// SCOREBOARD
// =====================================================
always @(posedge clk) begin
    if (rst_n) begin
        cycle = cycle + 1;

        // DATA CHECK
        if (rd_en && !rd_empty) begin
            if (rd_data !== model_rd_data) begin
                $display("ERROR at cycle %0d time %0t", cycle, $time);
                $display("Expected data = %0h, Got = %0h", model_rd_data, rd_data);
                $finish;
            end
        end

        // COUNT CHECK
        if (count !== model_count) begin
            $display("ERROR at cycle %0d time %0t", cycle, $time);
            $display("Expected count = %0d, Got = %0d", model_count, count);
            $finish;
        end

        // FLAG CHECKS
        if (rd_empty !== (model_count == 0)) begin
            $display("ERROR: rd_empty mismatch");
            $finish;
        end

        if (wr_full !== (model_count == DEPTH)) begin
            $display("ERROR: wr_full mismatch");
            $finish;
        end
    end
end

// =====================================================
// TEST SEQUENCE
// =====================================================
initial begin
    clk = 0;
    rst_n = 0;
    wr_en = 0;
    rd_en = 0;
    wr_data = 0;

    cov_full = 0;
    cov_empty = 0;
    cov_simul = 0;
    cov_overflow = 0;
    cov_underflow = 0;
    cycle = 0;

    // RESET
    #20 rst_n = 1;

    // RESET TEST
    #10;
    if (count != 0 || rd_empty != 1 || wr_full != 0) begin
        $display("RESET TEST FAILED");
        $finish;
    end
    $display("RESET TEST PASSED");

    // SINGLE WRITE/READ
    @(posedge clk);
    wr_en = 1; wr_data = 8'hAA;
    @(posedge clk);
    wr_en = 0;

    @(posedge clk);
    rd_en = 1;
    @(posedge clk);
    rd_en = 0;

    $display("SINGLE TEST PASSED");

    // FILL FIFO
    repeat (DEPTH) begin
        @(posedge clk);
        wr_en = 1;
        wr_data = $random;
    end
    @(posedge clk);
    wr_en = 0;

    $display("FILL TEST PASSED");

    // DRAIN FIFO
    repeat (DEPTH) begin
        @(posedge clk);
        rd_en = 1;
    end
    @(posedge clk);
    rd_en = 0;

    $display("DRAIN TEST PASSED");

    // OVERFLOW
    wr_en = 1;
    repeat (DEPTH+2) @(posedge clk);
    wr_en = 0;

    $display("OVERFLOW TEST PASSED");


    // COVERAGE
    #20;
    $display("\n===== COVERAGE =====");
    $display("Full        = %0d", cov_full);
    $display("Empty       = %0d", cov_empty);
    $display("Simultaneous= %0d", cov_simul);
    $display("Overflow    = %0d", cov_overflow);
    $display("Underflow   = %0d", cov_underflow);

    $display("\nALL TESTS PASSED");

    $finish;
end

// Pointer Wrap-Around Test
task pointer_wrap_test;
    integer i;
    begin
        $display("Running Pointer Wrap-Around Test");

        // Reset
        rst_n = 0;
        @(posedge clk);
        rst_n = 1;

        // Fill FIFO partially to move pointers near boundary
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(posedge clk);
            wr_en = 1;
            rd_en = 0;
            wr_data = i;
        end

        // Empty FIFO to move read pointer to boundary
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(posedge clk);
            wr_en = 0;
            rd_en = 1;
        end

        // Now do wrap-around operations
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(posedge clk);
            wr_en = 1;
            rd_en = 0;
            wr_data = i + 100;  // new data to track wrap
        end

        for (i = 0; i < DEPTH; i = i + 1) begin
            @(posedge clk);
            wr_en = 0;
            rd_en = 1;
        end

        $display("Pointer Wrap-Around Test Completed");
    end
endtask
endmodule