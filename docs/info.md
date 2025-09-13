<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

##  Design and Functional Verification of Error-Correcting FIFO Buffer with SECDED and ARQ 

This project implements a FIFO (First-In, First-Out) buffer with integrated error detection and correction and automatic retransmission mechanisms to ensure reliable data transmission. The FIFO temporarily stores incoming data and allows controlled reading and writing using enable signals. To maintain data integrity, the design incorporates a Single Error Correction, Double Error Detection (SECDED) scheme, which can correct single-bit errors and detect double-bit errors in each data word. When an error is detected, the Automatic Repeat reQuest (ARQ) mechanism is triggered, allowing the last transmitted data to be retransmitted until it is successfully acknowledged. The system provides acknowledgment (ack) for correct transmissions and negative acknowledgment (nack) when retransmission is required. By combining FIFO buffering, SECDED error correction, and ARQ-based retransmission, this design ensures that data is transmitted reliably even in the presence of errors, making it suitable for communication systems where data integrity and flow control are critical.

## How to test

we first need to create a testbench that simulates all possible scenarios, including normal transmission, corrupted transmission, and retransmission. The testbench drives the inputs like wr_en, rd_en, data_in, and err_mode, and monitors outputs such as data_out, ack, and nack to verify correct behavior. Once the simulation confirms that the module works as intended, you can organize the RTL code and testbench into a Git repository. Initialize the repository, add the files, commit the changes, and push them to your GitHub repository. Including the testbench and simulation waveforms in the repository ensures that others can reproduce and validate your design easily, making your project well-documented and ready for collaboration.

## External hardware

For the tx_fsm project, the external hardware used includes an FPGA development board, such as Xilinx Artix-7, Spartan-6, or Nexys A7, which is used to implement and test the module in hardware. A stable power supply is required to power the FPGA board. Optionally, a USB-to-UART converter like the FT232RL can be used to interface the FPGA with a PC for monitoring or debugging data. To verify the signals in real-time, an oscilloscope or logic analyzer can be employed. Push buttons or switches may be used to manually provide control signals like write enable, read enable, or reset during testing, and LEDs can be connected to indicate acknowledgment (ack) or retransmission (nack) signals, providing a visual representation of data transmission activity.
