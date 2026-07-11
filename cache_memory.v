module cache_memory #(
    parameter ADDR_WIDTH = 32,                                          // 32-bit address lines
    parameter DATA_WIDTH = 32,                                          // 32-bit data lines
    parameter BLOCKS = 16,                                              // Total number of blocks in cache memory
    parameter INDEX_WIDTH = $clog2(BLOCKS),                             // Number of bits in index
    parameter OFFSET_WIDTH = $clog2(DATA_WIDTH/8),                      // Number of bits in byte offset
    parameter TAG_WIDTH = ADDR_WIDTH - INDEX_WIDTH - OFFSET_WIDTH       // Number of bits in tag
)(
    input wire clk,                                                     // Clock
    input wire reset,                                                   // Reset

    input wire [INDEX_WIDTH-1:0] index,                                 // Input index from CPU request
    output wire [TAG_WIDTH-1:0] tag_out,                                // Tag data output
    output wire [DATA_WIDTH-1:0] data_out,                              // Cache memory data output
    output wire valid_out,                                              // Valid bit output
    output wire dirty_out,                                              // Dirty bit output

    input wire write_en,                                                // Write enable signal
    input wire [TAG_WIDTH-1:0] tag_in,                                  // Tag data input
    input wire [DATA_WIDTH-1:0] data_in,                                // Cache memory data input
    input wire valid_in,                                                // Valid bit input
    input wire dirty_in                                                 // Dirty bit input
);

    // Cache memory register
    reg [TAG_WIDTH-1:0] tag_array [0:BLOCKS-1];
    reg [DATA_WIDTH-1:0] data_array [0:BLOCKS-1];
    reg valid_array [0:BLOCKS-1];
    reg dirty_array [0:BLOCKS-1];

    integer i;

    // Combinational output of given index
    assign tag_out = tag_array[index];
    assign data_out = data_array[index];
    assign valid_out = valid_array[index];
    assign dirty_out = dirty_array[index];

    // Sequential reset and write operation
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < BLOCKS; i = i + 1) begin
                tag_array[i] <= {TAG_WIDTH{1'b0}};
                data_array[i] <= {DATA_WIDTH{1'b0}};
                valid_array[i] <= 1'b0;
                dirty_array[i] <= 1'b0;
            end
        end
        else if (write_en) begin
            tag_array[index] <= tag_in;
            data_array[index] <= data_in;
            valid_array[index] <= valid_in;
            dirty_array[index] <= dirty_in;
        end
    end
endmodule