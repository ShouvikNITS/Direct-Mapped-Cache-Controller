# Direct-Mapped Cache Controller with Write-Back Policy

A modular RTL implementation of a **Direct-Mapped Cache Controller** designed using **Verilog HDL**. The cache implements a **write-back and write-allocate policy** and uses a finite state machine (FSM) to manage cache hits, misses, dirty block eviction, and memory refill operations.

The design follows a modular architecture by separating the **cache controller, cache storage, and main memory model**, making the project easier to verify, debug, and extend.

## Features

- Direct-mapped cache architecture
- Write-back cache policy
- Write-allocate on write miss
- Parameterized address and data widths
- Parameterized number of cache lines
- Valid and dirty bit management
- Tag-based cache hit detection
- Dirty cache block eviction
- Main memory handshake interface
- FSM-based cache controller
- Modular Verilog RTL design
- Self-checking testbench
- Deadlock timeout detection
- VCD waveform generation for GTKWave

## Cache Configuration

| Parameter | Value |
|-----------|-------|
| Address Width | 32 bits |
| Data Width | 32 bits |
| Cache Size | 64 Bytes |
| Number of Cache Blocks | 16 |
| Block Size | 4 Bytes |
| Words per Block | 1 |
| Mapping | Direct Mapped |
| Write Policy | Write Back |
| Write Miss Policy | Write Allocate |
| Tag Width | 26 bits |
| Index Width | 4 bits |
| Byte Offset Width | 2 bits |

## Address Mapping

The 32-bit CPU address is divided into three fields:
- **Tag (26 bits):** Identifies the memory block stored in the cache line.
- **Index (4 bits):** Selects one of the 16 cache lines.
- **Byte Offset (2 bits):** Represents the byte position within a 32-bit word.

The cache line index is determined using:
Cache Index = (Memory Block Number) % (Number of Cache Lines)

## Cache Line Structure

Each cache line contains:

| Field | Width |
|-------|-------|
| Valid Bit | 1 bit |
| Dirty Bit | 1 bit |
| Tag | 26 bits |
| Data | 32 bits |

The cache data capacity is **64 bytes**, while tag and status metadata are stored separately.

## RTL Architecture

The project consists of the following modules:

### `direct_mapped_cache.v`

Top-level cache module responsible for integrating the cache controller and cache memory.

### `cache_controller.v`

Implements the cache control logic and FSM. It handles:

- CPU request latching
- Cache hit and miss detection
- Read and write operations
- Dirty block write-back
- Cache block allocation
- Write-allocate operations
- Main memory request generation

### `cache_memory.v`

Implements the cache storage using separate arrays for:

- Tag
- Data
- Valid bits
- Dirty bits

### `main_memory.v`

A parameterized main memory model used for simulation. It includes configurable memory latency and a request/ready handshake interface.

### `tb_direct_mapped_cache.v`

Self-checking Verilog testbench used to verify cache functionality.

## Cache Controller FSM

The cache controller uses five states:
### FSM States
- **IDLE:** Waits for a CPU request.
- **LOOKUP:** Performs tag comparison and cache hit detection.
- **WRITEBACK:** Writes a dirty cache block to main memory.
- **ALLOCATE:** Fetches the requested word from main memory.
- **UPDATE:** Updates the allocated cache line after a write miss.

## Cache Operation

### Read Hit

The requested data is directly returned from the cache.

### Write Hit

The cache data is updated and the dirty bit is set.

### Read Miss

If the victim cache line is clean, the requested data is fetched from main memory and allocated in the cache.

If the victim cache line is dirty, it is first written back to main memory before the requested data is fetched.

### Write Miss

The cache implements a write-allocate policy. The requested word is first fetched from main memory, allocated in the cache, updated with the CPU write data, and marked dirty.

## Verification

The self-checking testbench verifies:

1. Read miss
2. Read hit
3. Write hit
4. Reading modified dirty cache data
5. Dirty block eviction
6. Write-back verification
7. Write miss with write allocation
8. Write-allocate data verification

The testbench automatically reports PASS or FAIL for each read operation.

## Simulation

Compile using Icarus Verilog:

iverilog -g2012 -o cache_sim cache_memory.v cache_controller.v direct_mapped_cache.v main_memory.v tb_direct_mapped_cache.v

Run the simulation:

vvp cache_sim

View the generated waveform using GTKWave:

gtkwave cache.vcd

## Tools Used

- Verilog HDL
- Icarus Verilog
- GTKWave

## Future Improvements

- Multi-word cache blocks
- Configurable cache block size
- Multi-word dirty block write-back
- Byte-enable support
- Set-associative cache architecture
- AXI memory interface integration
