`timescale 1ns/1ps

module direct_mapped_cache #(
    parameter ADDR_WIDTH   = 32,
    parameter DATA_WIDTH   = 32,
    parameter NUM_LINES    = 16,
    parameter INDEX_WIDTH  = $clog2(NUM_LINES),
    parameter OFFSET_WIDTH = $clog2(DATA_WIDTH/8),
    parameter TAG_WIDTH    = ADDR_WIDTH - INDEX_WIDTH - OFFSET_WIDTH
)(
    input wire clk,
    input wire reset,

    // CPU interface
    input  wire                  cpu_req,
    input  wire                  cpu_write,
    input  wire [ADDR_WIDTH-1:0] cpu_addr,
    input  wire [DATA_WIDTH-1:0] cpu_wdata,

    output wire [DATA_WIDTH-1:0] cpu_rdata,
    output wire                  cpu_ready,

    // Memory interface
    output wire                  mem_req,
    output wire                  mem_write,
    output wire [ADDR_WIDTH-1:0] mem_addr,
    output wire [DATA_WIDTH-1:0] mem_wdata,

    input wire [DATA_WIDTH-1:0] mem_rdata,
    input wire                  mem_ready
);

    wire [INDEX_WIDTH-1:0] cache_index;

    wire [TAG_WIDTH-1:0]  cache_tag;
    wire [DATA_WIDTH-1:0] cache_data;

    wire cache_valid;
    wire cache_dirty;

    wire cache_write_en;

    wire [TAG_WIDTH-1:0]  cache_tag_in;
    wire [DATA_WIDTH-1:0] cache_data_in;

    wire cache_valid_in;
    wire cache_dirty_in;


    /*
     * Cache storage
     */

    cache_memory #(
        .ADDR_WIDTH   (ADDR_WIDTH),
        .DATA_WIDTH   (DATA_WIDTH),
        .NUM_LINES    (NUM_LINES),
        .INDEX_WIDTH  (INDEX_WIDTH),
        .OFFSET_WIDTH (OFFSET_WIDTH),
        .TAG_WIDTH    (TAG_WIDTH)
    ) cache_memory_inst (
        .clk   (clk),
        .reset (reset),

        .index (cache_index),

        .tag_out   (cache_tag),
        .data_out  (cache_data),
        .valid_out (cache_valid),
        .dirty_out (cache_dirty),

        .write_en (cache_write_en),

        .tag_in   (cache_tag_in),
        .data_in  (cache_data_in),
        .valid_in (cache_valid_in),
        .dirty_in (cache_dirty_in)
    );


    /*
     * Cache controller
     */

    cache_controller #(
        .ADDR_WIDTH   (ADDR_WIDTH),
        .DATA_WIDTH   (DATA_WIDTH),
        .NUM_LINES    (NUM_LINES),
        .INDEX_WIDTH  (INDEX_WIDTH),
        .OFFSET_WIDTH (OFFSET_WIDTH),
        .TAG_WIDTH    (TAG_WIDTH)
    ) cache_controller_inst (
        .clk   (clk),
        .reset (reset),

        .cpu_req   (cpu_req),
        .cpu_write (cpu_write),
        .cpu_addr  (cpu_addr),
        .cpu_wdata (cpu_wdata),

        .cpu_rdata (cpu_rdata),
        .cpu_ready (cpu_ready),

        .cache_index (cache_index),

        .cache_tag   (cache_tag),
        .cache_data  (cache_data),
        .cache_valid (cache_valid),
        .cache_dirty (cache_dirty),

        .cache_write_en (cache_write_en),

        .cache_tag_in   (cache_tag_in),
        .cache_data_in  (cache_data_in),
        .cache_valid_in (cache_valid_in),
        .cache_dirty_in (cache_dirty_in),

        .mem_req   (mem_req),
        .mem_write (mem_write),
        .mem_addr  (mem_addr),
        .mem_wdata (mem_wdata),

        .mem_rdata (mem_rdata),
        .mem_ready (mem_ready)
    );

endmodule