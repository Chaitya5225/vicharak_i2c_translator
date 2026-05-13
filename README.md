# FPGA I²C Address Translator
![Language](https://img.shields.io/badge/Language-Verilog-blue.svg)
![Tools](https://img.shields.io/badge/Tools-AMD_Xilinx_Vivado-orange.svg)

This repository contains the RTL, testbenches, and documentation for an FPGA-based I²C address translator. The design allows a single device's I²C address to be dynamically remapped, enabling it to coexist with other devices sharing the same default physical address.

###  Key Deliverables
* **Screen Recording :**  https://drive.google.com/drive/folders/1keifkrMtAtHTB24O1KSIDUoTONETHau6?usp=sharing
* **EDA Playground Simulation:** https://www.edaplayground.com/x/FW7j
* 
    **Note on Web Simulation: To prevent the EPWave web viewer from crashing due to VCD memory limits (a common issue with 100MHz system clocks over long timeframes), the clock dividers in         the EDA Playground link are scaled by 10x for visualization purposes. The RTL code in this repository and the Vivado synthesis reports use the strict, protocol-accurate 100kHz timing          (CLK_HALF_PERIOD = 500) as per the requirements.**
###  Repository Structure
* `/src/` - Contains the Verilog RTL modules (`top`, `master`, `slave`) and the simulation files (`mock_i2c_device`, `testbench`).
* `/reports/` - Contains the synthesis Resource Utilization Report (Basys-3 target) and the simulation waveform proof.
* `/docs/` - Contains the brief PDF documentation detailing the architecture, FSM logic, address translation strategy, and design challenges.

###  Design Overview
The system implements a bidirectional Store-and-Forward architecture using two independent FSMs. 
* The **Host-facing Slave** intercepts transactions targeting the virtual address (`0x49`) and utilizes synchronous clock stretching to pause the bus.
* The **Sensor-facing Master** forwards the buffered payload to the physical target address (`0x48`) at a standard 100kHz I²C timing.

<img width="1655" height="607" alt="image" src="https://github.com/user-attachments/assets/2450b5d7-7c96-4d0d-b647-5f8cbf1f9dd8" />

### Finite State Machine (FSM) Flow

```mermaid
stateDiagram-v2
    direction TB
    [*] --> IDLE : System Reset

    IDLE --> START_DETECT : SDA falling edge (SCL=1)
    
    START_DETECT --> SHIFT_ADDRESS : SCL toggling
    note right of SHIFT_ADDRESS: Shift in 7-bit Addr + R/W bit
    
    SHIFT_ADDRESS --> CHECK_MATCH : 8th SCL Edge
    
    CHECK_MATCH --> INTERCEPT : rx_addr == 0x49
    CHECK_MATCH --> BYPASS : rx_addr != 0x49
    
    INTERCEPT --> CLOCK_STRETCH : Pull SCL LOW
    note left of CLOCK_STRETCH: Hold Host Controller
    
    CLOCK_STRETCH --> TRANSMIT_NEW_ADDR : Send 0x48 to Bus
    TRANSMIT_NEW_ADDR --> DATA_PHASE : Target Slave ACKs
    
    BYPASS --> DATA_PHASE : Normal Passthrough
    
    DATA_PHASE --> DATA_PHASE : Tx/Rx 8-bit Data + ACK phase
    
    DATA_PHASE --> STOP_DETECT : SDA rising edge (SCL=1)
    
    STOP_DETECT --> IDLE : Transaction Complete
