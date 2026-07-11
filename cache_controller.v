module cache_controller #(
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
    input wire cpu_req,
    input wire cpu_write,
    input wire [ADDR_WIDTH-1:0] cpu_addr,
    input wire [DATA_WIDTH-1:0] cpu_wdata,

    output reg [DATA_WIDTH-1:0] cpu_rdata,
    output reg cpu_ready,

    // Cache interface
    output wire [INDEX_WIDTH-1:0] cache_index,

    input wire [TAG_WIDTH-1:0] cache_tag,
    input wire [DATA_WIDTH-1:0] cache_data,
    input wire cache_valid,
    input wire cache_dirty,

    output reg cache_write_en,
    output reg [TAG_WIDTH-1:0] cache_tag_in,
    output reg [DATA_WIDTH-1:0] cache_data_in,
    output reg cache_valid_in,
    output reg cache_dirty_in,

    // Main memory interface
    output reg mem_req,
    output reg mem_write,
    output reg [ADDR_WIDTH-1:0] mem_addr,
    output reg [DATA_WIDTH-1:0] mem_wdata,

    input wire [DATA_WIDTH-1:0] mem_rdata,
    input wire mem_ready
);
    // State declarations
    localparam IDLE = 3'd0;
    localparam LOOKUP = 3'd1;
    localparam WRITE_BACK = 3'd2;
    localparam ALLOCATE = 3'd3;
    localparam UPDATE = 3'd4;

    reg [2:0] state;

    reg [ADDR_WIDTH-1:0] req_addr;
    reg [DATA_WIDTH-1:0] req_wdata;
    reg req_write;

    wire [TAG_WIDTH-1:0] req_tag;
    wire [INDEX_WIDTH-1:0] req_index;

    wire cache_hit;

    assign req_tag = req_addr[ADDR_WIDTH-1:OFFSET_WIDTH + INDEX_WIDTH];
    assign req_index = req_addr[OFFSET_WIDTH + INDEX_WIDTH - 1:OFFSET_WIDTH];
    assign cache_index = req_index;
    assign cache_hit = cache_valid && (cache_tag == req_tag);

    // Sequential operation
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;

            req_addr <= {ADDR_WIDTH{1'b0}};
            req_wdata <= {DATA_WIDTH{1'b0}};
            req_write <= 1'b0;

            cpu_rdata <= {DATA_WIDTH{1'b0}};
            cpu_ready <= 1'b0;

            cache_write_en <= 1'b0;
            cache_tag_in <= {TAG_WIDTH{1'b0}};
            cache_data_in <= {DATA_WIDTH{1'b0}};
            cache_valid_in <= 1'b0;
            cache_dirty_in <= 1'b0;
        end
        else begin
            // Default values
            cpu_ready <= 1'b0;
            cache_write_en <= 1'b0;

            // Cache FSM : State control and cache output control
            case (state)

                IDLE: begin
                    if (cpu_req) begin
                        req_addr <= cpu_addr;
                        req_wdata <= cpu_wdata;
                        req_write <= cpu_write;
                        state <= LOOKUP;                    // Next state
                    end
                end

                LOOKUP: begin
                    // For HIT
                    if (cache_hit) begin
                        if (req_write) begin
                            cache_write_en <= 1'b1;
                            cache_tag_in <= req_tag;
                            cache_data_in <= req_wdata;
                            cache_valid_in <= 1'b1;
                            cache_dirty_in <= 1'b1;
                            cpu_ready <= 1'b1;
                        end
                        else begin
                            cpu_rdata <= cache_data;
                            cpu_ready <= 1'b1;
                        end
                        state <= IDLE;                      // Next state
                    end
                    // For MISS
                    else begin
                        // Next state
                        if (cache_valid && cache_dirty)
                            state <= WRITE_BACK;
                        else
                            state <= ALLOCATE;
                    end
                end

                WRITE_BACK: begin
                    if (mem_ready) begin
                        state <= ALLOCATE;
                    end
                end

                ALLOCATE: begin
                    if (mem_ready) begin
                        cache_write_en <= 1'b1;
                        cache_tag_in <= req_tag;
                        cache_data_in <= mem_rdata;
                        cache_valid_in <= 1'b1;
                        cache_dirty_in <= 1'b0;

                        // For Read MISS
                        if (!req_write) begin
                            cpu_rdata <= mem_rdata;
                            cpu_ready <= 1'b1;
                            state <= IDLE;
                        end
                        // For Write MISS
                        else begin
                            state <= UPDATE;
                        end
                    end
                end

                UPDATE: begin
                    cache_write_en <= 1'b1;

                    cache_tag_in <= req_tag;
                    cache_data_in <= req_wdata;
                    cache_valid_in <= 1'b1;
                    cache_dirty_in <= 1'b1;
                    cpu_ready <= 1'b1;
                    state <= IDLE;
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

    // Memory request logic
    // 'mem_req' is suppressed while 'mem_ready' is asserted,
    // to prevent the memory from re-accepting a completed
    // request before the FSM changes state.

    always @(*) begin
        // Default values
        mem_req = 1'b0;
        mem_write = 1'b0;
        mem_addr = {ADDR_WIDTH{1'b0}};
        mem_wdata = {DATA_WIDTH{1'b0}};

        case (state)

            WRITE_BACK: begin
                if (!mem_ready) begin
                    mem_req = 1'b1;
                    mem_write = 1'b1;
                    mem_addr = {cache_tag,req_index,{OFFSET_WIDTH{1'b0}}};
                    mem_wdata = cache_data;
                end
            end

            ALLOCATE: begin
                if (!mem_ready) begin
                    mem_req = 1'b1;
                    mem_write = 1'b0;
                    mem_addr = {req_tag,req_index,{OFFSET_WIDTH{1'b0}}};
                end
            end
        endcase
    end
endmodule