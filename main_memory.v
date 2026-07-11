`timescale 1ns/1ps

module main_memory #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter MEM_WORDS = 256,                                  // Total nummber of blocks in memory
    parameter LATENCY = 3,                                      // Simulate delay in fetching data from memory
    parameter OFFSET_WIDTH = $clog2(DATA_WIDTH/8),
    parameter MEM_AWIDTH = $clog2(MEM_WORDS)                    // Memory address width bits
)(
    input wire clk,
    input wire reset,

    input wire mem_req,
    input wire mem_write,
    input wire [ADDR_WIDTH-1:0] mem_addr,
    input wire [DATA_WIDTH-1:0] mem_wdata,

    output reg [DATA_WIDTH-1:0] mem_rdata,
    output reg mem_ready
);

    // Memory data register
    reg [DATA_WIDTH-1:0] memory [0:MEM_WORDS-1];
    reg busy;
    reg saved_write;
    reg [ADDR_WIDTH-1:0] saved_addr;
    reg [DATA_WIDTH-1:0] saved_wdata;

    integer counter;
    integer i;

    wire [MEM_AWIDTH-1:0] saved_word_addr;

    assign saved_word_addr = saved_addr[OFFSET_WIDTH + MEM_AWIDTH - 1:OFFSET_WIDTH];

    // Initialize memory with data
    initial begin
        for (i = 0; i < MEM_WORDS; i = i + 1)
            memory[i] = 32'h10000000 + i;
    end

    always @(posedge clk) begin
        if (reset) begin
            busy <= 1'b0;

            mem_ready <= 1'b0;
            mem_rdata <= {DATA_WIDTH{1'b0}};

            saved_write <= 1'b0;
            saved_addr  <= {ADDR_WIDTH{1'b0}};
            saved_wdata <= {DATA_WIDTH{1'b0}};

            counter <= 0;
        end
        else begin
            mem_ready <= 1'b0;

            // New request
            if (!busy && mem_req) begin
                busy <= 1'b1;

                saved_write <= mem_write;
                saved_addr  <= mem_addr;
                saved_wdata <= mem_wdata;

                counter <= LATENCY;
            end

            // Processing request
            else if (busy) begin
                // Latency simulate
                if (counter > 1) begin
                    counter <= counter - 1;
                end
                else begin
                    busy <= 1'b0;
                    mem_ready <= 1'b1;
                    // Write operation
                    if (saved_write) begin
                        memory[saved_word_addr] <= saved_wdata;
                        $display("[MEM WRITE] t=%0t addr=%h data=%h",$time,saved_addr,saved_wdata);
                    end
                    // Read operation
                    else begin
                        mem_rdata <= memory[saved_word_addr];
                        $display("[MEM READ] t=%0t addr=%h data=%h",$time,saved_addr,memory[saved_word_addr]);
                    end
                end
            end
        end
    end
endmodule