# Soc Lab4-2
## the content of the work
1.bram save firmware code(fir.hex)  at first.
2.Firmware code control CPU to transmit input x and control CPU to receive output data y.
3.user_proj_example.counter.v(hardware) use AXI-Lite and AXI-Stream and Wishbone interfaces to compute FIR's computation.
4.Use testbench to make FIR design run 3 times.
## Execute FIR Code in User Bram
### Simulation for FIR 
```shell
cd ~/caravel-soc_fpga-lab/lab-caravel_fir/testbench/counter_la_fir
source run_clean
source run_sim 



