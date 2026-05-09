# FPGA I²C Address Translator

This repository contains the RTL, testbenches, and documentation for an FPGA-based I²C address translator. The design allows a single device's I²C address to be dynamically remapped, enabling it to coexist with other devices sharing the same default physical address.

###  Key Deliverables
* **Screen Recording :**  https://drive.google.com/drive/folders/1keifkrMtAtHTB24O1KSIDUoTONETHau6?usp=sharing
* **EDA Playground Simulation:** https://www.edaplayground.com/x/FW7j

###  Repository Structure
* `/src/` - Contains the Verilog RTL modules (`top`, `master`, `slave`) and the simulation files (`mock_i2c_device`, `testbench`).
* `/reports/` - Contains the synthesis Resource Utilization Report (Basys-3 target) and the simulation waveform proof.
* `/docs/` - Contains the brief PDF documentation detailing the architecture, FSM logic, address translation strategy, and design challenges.

###  Design Overview
The system implements a bidirectional Store-and-Forward architecture using two independent FSMs. 
* The **Host-facing Slave** intercepts transactions targeting the virtual address (`0x49`) and utilizes synchronous clock stretching to pause the bus.
* The **Sensor-facing Master** forwards the buffered payload to the physical target address (`0x48`) at a standard 100kHz I²C timing.
