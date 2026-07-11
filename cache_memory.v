`timescale 1ns/1ps

module cache_memory #(
    parameter ADDR_WIDTH   = 32,
    parameter DATA_WIDTH   = 32,
    parameter NUM_LINES    = 16,
    parameter INDEX_WIDTH  = $clog2(NUM_LINES),
    parameter OFFSET_WIDTH = $clog2(DATA_WIDTH/8),
    parameter TAG_WIDTH    = ADDR_WIDTH - INDEX_WIDTH - OFFSET_WIDTH
)(
    input  wire                   clk,
    input  wire                   reset,

    input  wire [INDEX_WIDTH-1:0] index,

    output wire [TAG_WIDTH-1:0]   tag_out,
    output wire [DATA_WIDTH-1:0]  data_out,
    output wire                   valid_out,
    output wire                   dirty_out,

    input  wire                   write_en,
    input  wire [TAG_WIDTH-1:0]   tag_in,
    input  wire [DATA_WIDTH-1:0]  data_in,
    input  wire                   valid_in,
    input  wire                   dirty_in
);

    reg [TAG_WIDTH-1:0]  tag_array   [0:NUM_LINES-1];
    reg [DATA_WIDTH-1:0] data_array  [0:NUM_LINES-1];
    reg                  valid_array [0:NUM_LINES-1];
    reg                  dirty_array [0:NUM_LINES-1];

    integer i;

    assign tag_out   = tag_array[index];
    assign data_out  = data_array[index];
    assign valid_out = valid_array[index];
    assign dirty_out = dirty_array[index];

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < NUM_LINES; i = i + 1) begin
                tag_array[i]   <= {TAG_WIDTH{1'b0}};
                data_array[i]  <= {DATA_WIDTH{1'b0}};
                valid_array[i] <= 1'b0;
                dirty_array[i] <= 1'b0;
            end
        end
        else if (write_en) begin
            tag_array[index]   <= tag_in;
            data_array[index]  <= data_in;
            valid_array[index] <= valid_in;
            dirty_array[index] <= dirty_in;
        end
    end

endmodule