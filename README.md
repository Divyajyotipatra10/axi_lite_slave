# AXI Lite Slave Interface

<!-- Banner Image -->

![Banner Image](https://github.com/user-attachments/assets/ce292a21-9c43-42d7-a335-7a21de49c39f)


---

## About AXI Lite and AXI Full

The AXI Lite protocol is a lightweight subset of the full AXI (Advanced eXtensible Interface) protocol designed for simple, low-throughput control register access. Unlike AXI Full, which supports burst transactions and higher data throughput, AXI Lite handles single data transfers and is ideal for register-mapped peripherals with simpler requirements.

---

## AXI Lite Slave Interface Signals

| Signal Name    | Role Description                                               |
| -------------- | --------------------------------------------------------------|
| `s_axi_clk`    | Clock input for synchronous operation                          |
| `s_axi_resetn` | Active-low reset input, resets the AXI slave interface         |
| `s_axi_awaddr` | Write address bus                                              |
| `s_axi_awvalid`| Write address valid signal                                     |
| `s_axi_awready`| Write address ready signal                                     |
| `s_axi_wdata`  | Write data bus                                                |
| `s_axi_wstrb`  | Write strobes, byte-wise write enable                         |
| `s_axi_wvalid` | Write data valid signal                                       |
| `s_axi_wready` | Write data ready signal                                       |
| `s_axi_bresp`  | Write response status                                        |
| `s_axi_bvalid` | Write response valid signal                                  |
| `s_axi_bready` | Write response ready signal                                  |
| `s_axi_araddr` | Read address bus                                             |
| `s_axi_arvalid`| Read address valid signal                                    |
| `s_axi_arready`| Read address ready signal                                    |
| `s_axi_rdata`  | Read data bus                                               |
| `s_axi_rresp`  | Read response status                                      |
| `s_axi_rvalid` | Read data valid signal                                   |
| `s_axi_rready` | Read data ready signal                                   |

---

## Design Overview

This project implements a fully protocol-compliant AXI Lite Slave Interface in Verilog RTL. It features:

- Separate read and write address channels
- Full handshake support
- Address decode for multiple slave registers
- Response generation for invalid transactions

The design is minimal in logic and resource usage, making it highly reusable and adaptable for various IP blocks.

---

## Resource Utilization

The module uses minimal FPGA resources and is optimized for efficient implementation.

<!-- Insert resource utilization image below -->
![Resource Utilization](https://github.com/user-attachments/assets/8a8882a3-c54f-46ed-8623-5750526e4407)


---

## Testbench Verification

All AXI Lite behaviors were tested with edge cases and stress conditions. Testbench written in SystemVerilog and executed using ModelSim.

### List of Verified Features:

1. Reset Verification  
2. Single Write Transaction  
3. Single Read Transaction  
4. Simultaneous Read and Write Transaction  
5. Invalid Write Address Transaction  
6. Invalid Read Address Transaction  
7. Back-to-Back Write Transactions  
8. Back-to-Back Read Transactions  
9. Back-to-Back Read + Write Combined  
10. WVALID Backpressure Test  
11. BREADY Backpressure Test  
12. RREADY Backpressure Test  

---

### 🔹 Reset Verification

Verifies slave resets all internal state correctly on `s_axi_resetn` assertion.

![Reset Verification](https://github.com/user-attachments/assets/af3e5939-cb9b-42ba-b700-be8e76692ba9)

---

### 🔹 Single Write Transaction

Validates a proper AW-W-B write flow with correct acknowledgment and memory update.

![Single Write]((https://github.com/user-attachments/assets/1ddb19cb-e287-4d53-a21c-5799f052454a))

---

### 🔹 Single Read Transaction

Confirms proper AR-R response and data retrieval from slave memory.

![Single Read]((https://github.com/user-attachments/assets/b5e581a5-180f-4d40-ae3f-cd892b628006))

---

### 🔹 Simultaneous Read and Write Transaction

Tests parallel handling of read and write channels independently.

![Simultaneous RW]((https://github.com/user-attachments/assets/cd2cee58-4923-465d-8987-725add6c5ec0))

---

### 🔹 Invalid Write Address Transaction

Checks response for a write to an unmapped/invalid address.

![Invalid Write]((https://github.com/user-attachments/assets/d98f6817-1691-46e1-a28e-f3eb7f2305a7))

---

### 🔹 Invalid Read Address Transaction

Checks response for a read from an unmapped/invalid address.

![Invalid Read]((https://github.com/user-attachments/assets/53438d2b-076c-4047-aa05-3f8500ae9a36))

---

### 🔹 Back-to-Back Write Transactions

Tests pipelined write bursts with consecutive AW-W handshakes.

![B2B Write]((https://github.com/user-attachments/assets/be16e783-e328-4760-832d-8a26a26c1bef))

---

### 🔹 Back-to-Back Read Transactions

Tests pipelined reads with back-to-back AR handshakes.

![B2B Read]((https://github.com/user-attachments/assets/e4ceafd2-0bae-4f0a-acf2-3e462f5784cc))

---

### 🔹 Combined Back-to-Back Write + Read

Tests interleaved pipelined writes and reads.

![B2B RW]((https://github.com/user-attachments/assets/10138772-5eae-4b6d-b417-629556ad3bde))

---

### 🔹 WVALID Backpressure Test

Verifies proper slave stalling when WVALID asserted without WREADY available.

![WVALID BP]((https://github.com/user-attachments/assets/e3d72289-b305-4116-b5a7-61fcf174d70e))

---

### 🔹 BREADY Backpressure Test

Checks slave behavior when master delays readout of write response.

![BREADY BP]((https://github.com/user-attachments/assets/7a3f9fca-389c-4ace-847e-f99c30b2af6c))

---

### 🔹 RREADY Backpressure Test

Verifies slave stalls read channel when RREADY is low.

![RREADY BP]((https://github.com/user-attachments/assets/c473fd7c-340b-4202-8bee-a4eaed6f08b0))

---

## Complete Waveform
![OUTPUT WAVE](https://github.com/user-attachments/assets/ba5192bf-fdf8-4b26-9529-d4fbe51d3554)

## TCL Simulation Output

TCL script output from ModelSim simulation showing successful execution.

![TCL Output](https://github.com/user-attachments/assets/8c606f42-c659-41e8-9afa-9677288745c9)
