# SOC Design Lab4-2
Reference: [lab-caravel_fir](https://github.com/bol-edu/caravel-soc_fpga-lab/tree/main/lab-caravel_fir)
## the content of the work
1. bram save firmware code at first.  
2. fir.h define FIR reg address.  
3. Firmware code control CPU to transmit input x and control CPU to receive output data y.  
4. user_proj_example.counter.v(hardware) use AXI-Lite and AXI-Stream and Wishbone interfaces to compute FIR's   computation.  
5. make FIR design run 3 times.  
## Firmware
* [counter_la_fir.c](/counter_la_fir.c)
* [fir.h](/fir.h)
* [fir.c](/fir.c)
* [counter_la_fir.hex](/counter_la_fir.hex)
## Hardware
* [user_proj_example.counter.v](/user_proj_example.counter.v)
* [bram.v](/bram.v)
* [bram11.v](/bram11.v)
## Testbench
* [counter_la_fir_tb.v](/counter_la_fir_tb.v)
## Log and Report
* [simulation log](/simulation.log)
* [synthesis report](/user_proj_example.vds)
* [utilization report](/user_proj_example_utilization_synth.rpt)
* [timing report](/timing_report.txt)
## Execute FIR Code in User Bram
### Simulation for FIR 
```shell
cd ~/caravel-soc_fpga-lab/lab-caravel_fir/testbench/counter_la_fir
source run_clean
source run_sim 
```



