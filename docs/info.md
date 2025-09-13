<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

##  Design and Functional Verification of Error-Correcting FIFO Buffer with SECDED and ARQ 

This project implements a FIFO (First-In, First-Out) buffer with integrated error detection and correction and automatic retransmission mechanisms to ensure reliable data transmission. The FIFO temporarily stores incoming data and allows controlled reading and writing using enable signals. To maintain data integrity, the design incorporates a Single Error Correction, Double Error Detection (SECDED) scheme, which can correct single-bit errors and detect double-bit errors in each data word. When an error is detected, the Automatic Repeat reQuest (ARQ) mechanism is triggered, allowing the last transmitted data to be retransmitted until it is successfully acknowledged. The system provides acknowledgment (ack) for correct transmissions and negative acknowledgment (nack) when retransmission is required. By combining FIFO buffering, SECDED error correction, and ARQ-based retransmission, this design ensures that data is transmitted reliably even in the presence of errors, making it suitable for communication systems where data integrity and flow control are critical.

## How to test

To test the project, a Verilog testbench is created to simulate all possible scenarios, including normal data transmission, single-bit errors, double-bit errors, and retransmission events. The testbench drives the inputs such as write enable, read enable, and data signals, while monitoring outputs like the transmitted data, acknowledgment (ack), and negative acknowledgment (nack). During simulation, single-bit errors are injected to verify that the SECDED logic correctly identifies and corrects errors, and double-bit errors are used to check proper detection without correction. The ARQ mechanism is tested by asserting retransmission requests and verifying that the last transmitted data is resent until acknowledged. Simulation results are observed through waveform outputs to ensure correct pointer behavior, data integrity, and proper acknowledgment signals. Once verified in simulation, the design can be implemented on an FPGA, where physical inputs such as switches and push buttons can mimic write/read operations, and LEDs or a UART interface can indicate transmission success or retransmission events. This testing process ensures the FIFO buffer works reliably under all conditions.

## External hardware

For the tx_fsm project, the external hardware used includes an FPGA development board, such as Xilinx Artix-7, Spartan-6, or Nexys A7, which is used to implement and test the module in hardware. A stable power supply is required to power the FPGA board. Optionally, a USB-to-UART converter like the FT232RL can be used to interface the FPGA with a PC for monitoring or debugging data. To verify the signals in real-time, an oscilloscope or logic analyzer can be employed. Push buttons or switches may be used to manually provide control signals like write enable, read enable, or reset during testing, and LEDs can be connected to indicate acknowledgment (ack) or retransmission (nack) signals, providing a visual representation of data transmission activity.
