# RISC CPU: 16-bit Custom Processor in VHDL

This project implements a custom 16-bit RISC-style CPU in VHDL, encompassing the core components of a general-purpose processor. The design follows a modular structure with a functional ALU, ROM and RAM integration, a register bank, and a 9-state control state machine. The instruction set was provided, but architectural freedom allowed personalized control flow and hardware structuring.

## ALU Design

Located in `alu.vhd`, the Arithmetic Logic Unit performs all standard arithmetic and logic operations asynchronously. It also generates four condition flags for later branching and conditional behavior:

- **Zero Flag (cr(0))** – Set if result is all zeros.  
- **Overflow Flag (cr(1))** – Set when signed overflow occurs during addition/subtraction.  
- **Negative Flag (cr(2))** – Set if the sign bit (bit 15) of the result is 1.  
- **Carry-Out Flag (cr(3))** – Set from the 17th bit (`tdest(16)`) on bit-shifts and arithmetic operations.

These outputs drive condition-based instruction behavior and return precise feedback for branching and ALU integrity.

## CPU Top-Level Design

Implemented in `cpu.vhd`, the CPU design integrates the ALU and follows a 9-state finite state machine:

1. **Start** – Initializes the CPU and waits for stabilization.  
2. **Fetch** – Retrieves instruction from ROM and increments the Program Counter (PC).  
3. **Execute-Setup** – Prepares operands and instruction-specific setup.  
4. **Execute-ALU** – Routes data through the ALU for operations.  
5. **Execute-MemoryWait** – Waits for memory access latency when required.  
6. **Execute-Write** – Writes data to memory or registers.  
7. **Execute-ReturnPause1** – Used for multi-cycle RETURN routines.  
8. **Execute-ReturnPause2** – Finalizes RETURN, returning to the calling context.  
9. **Halt** – Stops all operation until reset.

The CPU uses dedicated registers: `A-E`, `SP`, `MBR`, `IR`, `PC`, and a 4-bit `Condition Register`. This setup supports basic call stacks, memory operations, and return sequencing.

## Testing

A complete set of simulation waveforms is included, visualized using GTKWave:

- ALU Tests – `alutestbench.vhd`
- Full CPU Benchmarks – `cpubench.vhd` (4 views)
- Instruction ROM Programs:  
  - `testpush.mif` – Stack push behavior  
  - `testcall.mif` – Call/return sequence  
  - `testfibo.mif` – Fibonacci number generator (output shown in hex)

## File Structure

- **Project/**
  - `alu.vhd`, `cpu.vhd`, `ProgramRom.vhd`, `DataRAM.vhd` – Core logic
  - `*.mif` – Program ROM files
  - `*.vhd` – Testbenches and verification units
  - GTKWave screenshots demonstrating execution and correct operation

- **Project7_Report_AayanShah.pdf / .docx**  
  Full write-up and design rationale

## Acknowledgements

Thanks to Azam, Maya, and Aleksandra for code reviews and discussions. Also grateful to Professors Dr. Stephanie and Dr. Tahiya Chowdhury for their guidance. Forums like Reddit and Stack Overflow were invaluable for resolving design issues and verifying CPU behavior.

## Author

**Aayan Shah**  
Computer Science & Physics Student  
[GitHub Profile](https://github.com/aayans314)
