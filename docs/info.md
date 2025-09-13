<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

##  Design and Functional Verification of Error-Correcting FIFO Buffer with SECDED and ARQ 

The project implements a transmit finite state machine (TX FSM) with a small FIFO buffer to manage data transmission reliably. Incoming data is temporarily stored in the FIFO on a write enable signal, and a read enable signal triggers transmission. The module supports three modes: normal transmission, corrupted transmission, and retransmission. In normal mode, data is sent from the FIFO, the last transmitted data is saved, and an acknowledgment (ack) is raised. In corrupted mode, data is intentionally altered before sending to simulate transmission errors, while still signaling ack. In retransmission mode, the last transmitted data is resent, and a retransmission signal (nack) is raised. This design ensures reliable communication by handling errors and retransmissions, making it suitable for systems where data integrity and flow control are critical.

## How to test

we first need to create a testbench that simulates all possible scenarios, including normal transmission, corrupted transmission, and retransmission. The testbench drives the inputs like wr_en, rd_en, data_in, and err_mode, and monitors outputs such as data_out, ack, and nack to verify correct behavior. Once the simulation confirms that the module works as intended, you can organize the RTL code and testbench into a Git repository. Initialize the repository, add the files, commit the changes, and push them to your GitHub repository. Including the testbench and simulation waveforms in the repository ensures that others can reproduce and validate your design easily, making your project well-documented and ready for collaboration.

## External hardware

For the tx_fsm project, the external hardware used includes an FPGA development board, such as Xilinx Artix-7, Spartan-6, or Nexys A7, which is used to implement and test the module in hardware. A stable power supply is required to power the FPGA board. Optionally, a USB-to-UART converter like the FT232RL can be used to interface the FPGA with a PC for monitoring or debugging data. To verify the signals in real-time, an oscilloscope or logic analyzer can be employed. Push buttons or switches may be used to manually provide control signals like write enable, read enable, or reset during testing, and LEDs can be connected to indicate acknowledgment (ack) or retransmission (nack) signals, providing a visual representation of data transmission activity.
