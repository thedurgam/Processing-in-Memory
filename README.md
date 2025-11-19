# Processing-in-Memory
# Design and Simulation of SPAR-2 Architecture for Matrix Computation

## 📌 Project Overview
This project focuses on the design and simulation of a **SPAR-2 (Spatial Array Processor)** based architecture to efficiently handle **Matrix-Vector Multiplication (MVM)** operations. [cite_start]The design aims to mitigate the "Memory Wall" and "Von Neumann Bottleneck" prevalent in modern AI/ML workloads by implementing a **Near-Memory Computing (NMC)** approach[cite: 342, 346].

The architecture is implemented in **Verilog HDL** and verified using **Xilinx Vivado**. [cite_start]It features a scalable 2D mesh of Processing Elements (PEs) capable of concurrent data transfer and computation[cite: 349, 352].

## 🚀 Motivation
* [cite_start]**The Problem:** Traditional Von Neumann architectures suffer from high latency and energy consumption due to excessive data movement between the CPU and memory, particularly for data-intensive tasks like Deep Neural Networks (DNNs)[cite: 341, 342].
* **The Solution:** Moving computation closer to memory (Near-Memory Computing) reduces data movement overhead. [cite_start]This project utilizes the SPAR-2 architecture, a Reduced Instruction Set Computer (RISC) based spatial array, to perform parallel matrix computations efficiently[cite: 348, 349].

## 🏗️ System Architecture
The system is built around a centrally controlled array of Processing Elements (PEs).

### 1. Top-Level Organization
* [cite_start]**Global Controller:** Fetches instructions, decodes them, and broadcasts control signals to the PE array[cite: 352].
* **PE Array:** A $4\times4$ mesh of Processing Elements that perform the actual computations.
* [cite_start]**BRAM (Block RAM):** Used for storing input matrices/vectors and storing resultants, simulating near-memory storage[cite: 352].

### 2. Processing Element (PE) Design
Each PE is a lightweight computing unit containing:
* [cite_start]**Router:** Facilitates data movement between North, South, East, and West neighbors[cite: 356].
* [cite_start]**ALU:** Performs arithmetic operations (Add, Sub, Logic)[cite: 358].
* [cite_start]**Multiplier:** Implements **Booth’s Algorithm** for efficient multiplication[cite: 358].
* [cite_start]**Local Registers:** A Register File (R0-R3) for storing temporary operands[cite: 356].

## 📂 Repository Structure

```text
├── docs/
│   ├── MTP1_updated_report.pdf    # Detailed project thesis and literature survey
│   └── mtp_ppt_final.pdf          # Presentation slides summarizing the project
├── rtl/
│   ├── top.v                      # Top-level module integrating Controller, PE Array, and BRAM
│   ├── Controller.v               # Main FSM and instruction decoder
│   ├── PE.v                       # Processing Element logic (Router + ALU)
│   ├── alu.v                      # Arithmetic Logic Unit
│   ├── mul.v                      # Booth Multiplier implementation
│   ├── bit_serial_add.v           # Bit-serial adder logic
│   ├── BRAM.v                     # Block RAM simulation model
│   └── ctrl.v                     # Control logic helper modules
└── README.md
