module direct_mapped_cache #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter BLOCKS = 16,
    parameter INDEX_WIDTH = $clog2(BLOCKS),
    parameter OFFSET_WIDTH = $clog2(DATA_WIDTH/8),
    parameter TAG_WIDTH = ADDR_WIDTH - INDEX_WIDTH - OFFSET_WIDTH
)(
    input wire clk,
    input wire reset,

    // CPU interface
    input wire cpu_req,                                 // Request from CPU
    input wire cpu_write,                               // Write request from CPU
    input wire [ADDR_WIDTH-1:0] cpu_addr,               // CPU request address
    input wire [DATA_WIDTH-1:0] cpu_wdata,              // CPU write data

    output wire [DATA_WIDTH-1:0] cpu_rdata,             // CPU read data
    output wire cpu_ready,                              // CPU ready

    // Memory interface
    output wire mem_req,                                // Request to memory
    output wire mem_write,                              // Memory write request
    output wire [ADDR_WIDTH-1:0] mem_addr,              // Memory address
    output wire [DATA_WIDTH-1:0] mem_wdata,             // Memory write data

    input wire [DATA_WIDTH-1:0] mem_rdata,              // Memory read data
    input wire mem_ready                                // Memory ready
);

    wire [INDEX_WIDTH-1:0] cache_index;

    wire [TAG_WIDTH-1:0] cache_tag;
    wire [DATA_WIDTH-1:0] cache_data;

    wire cache_valid;
    wire cache_dirty;

    wire cache_write_en;

    wire [TAG_WIDTH-1:0] cache_tag_in;
    wire [DATA_WIDTH-1:0] cache_data_in;

    wire cache_valid_in;
    wire cache_dirty_in;


    // Cache memory
    cache_memory #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .BLOCKS(BLOCKS),
        .INDEX_WIDTH(INDEX_WIDTH),
        .OFFSET_WIDTH(OFFSET_WIDTH),
        .TAG_WIDTH(TAG_WIDTH)
    ) cache_memory_inst (
        .clk(clk),
        .reset(reset),
        .index(cache_index),
        .tag_out(cache_tag),
        .data_out(cache_data),
        .valid_out(cache_valid),
        .dirty_out(cache_dirty),
        .write_en(cache_write_en),
        .tag_in(cache_tag_in),
        .data_in(cache_data_in),
        .valid_in(cache_valid_in),
        .dirty_in(cache_dirty_in)
    );

    // Cache controller
    cache_controller #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .BLOCKS(BLOCKS),
        .INDEX_WIDTH(INDEX_WIDTH),
        .OFFSET_WIDTH(OFFSET_WIDTH),
        .TAG_WIDTH(TAG_WIDTH)
    ) cache_controller_inst (
        .clk(clk),
        .reset(reset),
        .cpu_req(cpu_req),
        .cpu_write(cpu_write),
        .cpu_addr(cpu_addr),
        .cpu_wdata(cpu_wdata),
        .cpu_rdata(cpu_rdata),
        .cpu_ready(cpu_ready),
        .cache_index(cache_index),
        .cache_tag(cache_tag),
        .cache_data(cache_data),
        .cache_valid(cache_valid),
        .cache_dirty(cache_dirty),
        .cache_write_en(cache_write_en),
        .cache_tag_in(cache_tag_in),
        .cache_data_in(cache_data_in),
        .cache_valid_in(cache_valid_in),
        .cache_dirty_in(cache_dirty_in),
        .mem_req(mem_req),
        .mem_write(mem_write),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_rdata(mem_rdata),
        .mem_ready(mem_ready)
    );
endmodule