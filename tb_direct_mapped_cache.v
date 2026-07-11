`timescale 1ns/1ps
module tb_direct_mapped_cache;

    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;
    parameter BLOCKS = 16;
    parameter MEM_WORDS = 256;

    reg clk;
    reg reset;

    reg cpu_req;
    reg cpu_write;
    reg [ADDR_WIDTH-1:0] cpu_addr;
    reg [DATA_WIDTH-1:0] cpu_wdata;

    wire [DATA_WIDTH-1:0] cpu_rdata;
    wire cpu_ready;

    wire mem_req;
    wire mem_write;
    wire [ADDR_WIDTH-1:0] mem_addr;
    wire [DATA_WIDTH-1:0] mem_wdata;

    wire [DATA_WIDTH-1:0] mem_rdata;
    wire mem_ready;

    integer pass_count;
    integer fail_count;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Cache  initialise
    direct_mapped_cache #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .BLOCKS(BLOCKS)
    )DUT(
        .clk(clk),
        .reset(reset),
        .cpu_req(cpu_req),
        .cpu_write(cpu_write),
        .cpu_addr(cpu_addr),
        .cpu_wdata(cpu_wdata),
        .cpu_rdata(cpu_rdata),
        .cpu_ready(cpu_ready),
        .mem_req(mem_req),
        .mem_write(mem_write),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_rdata(mem_rdata),
        .mem_ready(mem_ready)
    );

    //Memory initialise
    main_memory #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .MEM_WORDS(MEM_WORDS),
        .LATENCY(3)
    ) MEMORY (
        .clk(clk),
        .reset(reset),
        .mem_req(mem_req),
        .mem_write(mem_write),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_rdata(mem_rdata),
        .mem_ready(mem_ready)
    );

    // TASKS
    task cpu_read;
        input [ADDR_WIDTH-1:0] address;
        input [DATA_WIDTH-1:0] expected;

        begin
            @(negedge clk);
            cpu_addr = address;
            cpu_wdata = 0;
            cpu_write = 1'b0;
            cpu_req = 1'b1;

            @(negedge clk);
            cpu_req = 1'b0;
            wait(cpu_ready == 1'b1);

            if (cpu_rdata === expected) begin
                $display("[PASS] READ addr=%h data=%h",address,cpu_rdata);
                pass_count = pass_count + 1;
            end
            else begin
                $display("[FAIL] READ addr=%h expected=%h got=%h",address,expected,cpu_rdata);
                fail_count = fail_count + 1;
            end
            @(negedge clk);
        end
    endtask

    task cpu_write_task;
        input [ADDR_WIDTH-1:0] address;
        input [DATA_WIDTH-1:0] data;

        begin
            @(negedge clk);
            cpu_addr = address;
            cpu_wdata = data;
            cpu_write = 1'b1;
            cpu_req = 1'b1;

            @(negedge clk);
            cpu_req = 1'b0;
            wait(cpu_ready == 1'b1);

            $display("[WRITE COMPLETE] addr=%h data=%h",address,data);
            @(negedge clk);
        end
    endtask

    // Test Sequence
    initial begin
        $dumpfile("cache.vcd");
        $dumpvars(0, tb_direct_mapped_cache);

        reset = 1'b1;
        cpu_req = 1'b0;
        cpu_write = 1'b0;
        cpu_addr = 0;
        cpu_wdata = 0;

        pass_count = 0;
        fail_count = 0;

        repeat(4) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;

        $display("\nTEST 1: READ MISS");
        cpu_read(32'h00000000,32'h10000000);

        $display("\nTEST 2: READ HIT");
        cpu_read(32'h00000000,32'h10000000);

        $display("\nTEST 3: WRITE HIT");
        cpu_write_task(32'h00000000,32'hDEADBEEF);

        $display("\nTEST 4: READ DIRTY DATA");
        cpu_read(32'h00000000,32'hDEADBEEF);

        $display("\nTEST 5: DIRTY EVICTION");
        cpu_read(32'h00000040,32'h10000010);

        $display("\nTEST 6: VERIFY WRITE BACK");
        cpu_read(32'h00000000,32'hDEADBEEF);

        $display("\nTEST 7: WRITE MISS");
        cpu_write_task(32'h00000084,32'hCAFEBABE);

        $display("\nTEST 8: VERIFY WRITE ALLOCATE");
        cpu_read(32'h0000_0084,32'hCAFE_BABE);

        $display("CACHE TEST SUMMARY");
        $display("PASS = %0d", pass_count);
        $display("FAIL = %0d", fail_count);

        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("CACHE TEST FAILED");
        #20;
        $finish;
    end

    // Watchdog Timer
    initial begin
        #10000;
        $display("[FATAL] Simulation timeout - possible deadlock");
        $finish;
    end
endmodule