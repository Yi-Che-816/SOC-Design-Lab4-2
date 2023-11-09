// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module user_proj_example #(
    parameter BITS = 32
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq
);
    wire clk;
    wire rst;

    wire [`MPRJ_IO_PADS-1:0] io_in;
    wire [`MPRJ_IO_PADS-1:0] io_out;
    wire [`MPRJ_IO_PADS-1:0] io_oeb;

    wire [31:0] user_data; 
    reg [31:0] fir_data;
    wire [31:0] wdata;
    wire [BITS-1:0] count;

    wire user_valid;
    wire fir_valid;
    wire [31:0] la_write;
    wire exmem;
    wire hardware;
    reg user_ready;
    wire fir_ready;
    wire awready;
    reg awvalid;
    reg [11:0]awaddr;
    wire wready;
    reg wvalid;
    wire arready;
    reg arvalid;
    reg [11:0]araddr;
    reg rready;
    wire rvalid;
    wire [31:0]rdata;
    wire ss_tready;
    reg ss_tvalid; 
    reg sm_tready; 
    wire sm_tvalid; 
    wire [31:0]sm_tdata; 
    wire sm_tlast;
    wire tap_WE;
    wire tap_RE;
    wire [11:0]tap_WADDR;
    wire [11:0]tap_RADDR;
    wire [31:0]tap_Di;
    wire [31:0]tap_Do;
    wire data_WE;
    wire data_RE;
    wire [11:0]data_WADDR;
    wire [11:0]data_RADDR;
    wire [31:0]data_Di;
    wire [31:0]data_Do;

    assign user_valid = wbs_cyc_i && wbs_stb_i && exmem; 
    assign fir_valid = wbs_cyc_i && wbs_stb_i && hardware;//executing fir
    assign wdata = wbs_dat_i;
    assign wbs_ack_o = user_ready | fir_ready;//output back to CPU
    assign fir_ready = fir_valid ? (wready | rvalid | ss_tready | sm_tvalid): 1'b0;

    assign io_out = wbs_dat_o;
    assign io_oeb = {(`MPRJ_IO_PADS-1){rst}};


    assign irq = 3'b000;	// Unused

    //assign la_data_out = {{(127-BITS){1'b0}}, count};

    //assign la_write = ~la_oenb[63:32] & ~{BITS{valid}};
     
    assign clk = (~la_oenb[64]) ? la_data_in[64]: wb_clk_i;
    assign rst = (~la_oenb[65]) ? la_data_in[65]: wb_rst_i;
    assign wbs_dat_o = fir_valid ? fir_data: user_data;
    assign exmem = wbs_adr_i[31:20] == 12'h380 ? 1'b1 : 1'b0;
    assign hardware = wbs_adr_i[31:20] == 12'h300 ? 1'b1 : 1'b0;
    
    always @(posedge clk) begin
        if (rst) begin
            user_ready <= 0;
        end else begin
            user_ready <= 0;
            if ( user_valid && !user_ready ) begin
                   user_ready <= 1;
            end
        end
    end
    
    //covert wishbone to axi-lite and stream
    always @*
    begin
        if(fir_valid)
        begin
            if((8'h80<=wbs_adr_i[7:0])&&(wbs_adr_i[7:0]<=8'hA8))//tap
            begin
                awaddr = {4'd0,wbs_adr_i[7:0]};
                araddr = {4'd0,wbs_adr_i[7:0]};
                awvalid = 1;
                arvalid = 0;
                wvalid = 1;
                rready = 0;
                ss_tvalid = 0;
                sm_tready = 0;
                fir_data = wbs_dat_i;
            end
            else if(wbs_adr_i[7:0]==8'h00)
            begin
                awaddr = {4'd0,wbs_adr_i[7:0]};
                araddr = {4'd0,wbs_adr_i[7:0]};
                awvalid = 1;
                arvalid = 0;
                wvalid = 1;
                rready = 0;
                ss_tvalid = 0;
                sm_tready = 0;
                fir_data = wbs_dat_i;
            end
            else if(wbs_adr_i[7:0]==8'h10)
            begin
                awaddr = {4'd0,wbs_adr_i[7:0]};
                araddr = {4'd0,wbs_adr_i[7:0]};
                awvalid = 1;
                arvalid = 0;
                wvalid = 1;
                rready = 0;
                ss_tvalid = 0;
                sm_tready = 0;
                fir_data = wbs_dat_i;
            end
            else if(wbs_adr_i[7:0]==8'hC0)
            begin
                awaddr = 12'd0;
                araddr = 12'd0;
                awvalid = 0;
                arvalid = 0;
                wvalid = 0;
                rready = 0;
                ss_tvalid = 1;
                sm_tready = 1;
                fir_data = sm_tdata;
            end
            else if(wbs_adr_i[7:0]==8'hC8)
            begin
                awaddr = 12'd0;
                araddr = 12'd0;
                awvalid = 0;
                arvalid = 0;
                wvalid = 0;
                rready = 0;
                ss_tvalid = 0;
                sm_tready = 1;
                fir_data = sm_tdata;
            end
            else
            begin
                awaddr = 12'd0;
                araddr = 12'd0;
                awvalid = 0;
                arvalid = 0;
                wvalid = 0;
                rready = 0;
                ss_tvalid = 0;
                sm_tready = 1;
                fir_data = 32'd0;
            end
        end
        else
        begin
            awaddr = 12'd0;
            araddr = 12'd0;
            awvalid = 0;
            arvalid = 0;
            wvalid = 0;
            rready = 0;
            ss_tvalid = 0;
            sm_tready = 0;
            fir_data = 32'd0;
        end
    end
    bram user_bram (
        .CLK(clk),
        .WE0(wbs_sel_i & {4{wbs_we_i}}),
        .EN0(user_valid),
        .Di0(wbs_dat_i),
        .Do0(user_data),
        .A0(wbs_adr_i)
    );
    
    fir FIR
    (
    // AXI-Lite AW channel
    .awready(awready),
    .awvalid(awvalid),
    .awaddr(awaddr),
    // AXI-Lite W channel
    .wready(wready),
    .wvalid(wvalid),
    .wdata(wbs_dat_i),
    // AXI-Lite AR channel
    .arready(arready),
    .arvalid(arvalid),
    .araddr(araddr),
    // AXI-Lite R channel
    .rready(rready),
    .rvalid(rvalid),
    .rdata(rdata),
    // AXI-Stream slave
    .ss_tready(ss_tready),
    .ss_tvalid(ss_tvalid), 
    .ss_tdata(wbs_dat_i), 
    .ss_tlast(), 
    // AXI-Stream master
    .sm_tready(sm_tready), 
    .sm_tvalid(sm_tvalid), 
    .sm_tdata(sm_tdata), 
    .sm_tlast(sm_tlast), 
    // bram for tap RAM
    .tap_WE(tap_WE),
    .tap_RE(tap_RE),
    .tap_WADDR(tap_WADDR),
    .tap_RADDR(tap_RADDR),
    .tap_Di(tap_Di),
    .tap_Do(tap_Do),
    // bram for data RAM
    .data_WE(data_WE),
    .data_RE(data_RE),
    .data_WADDR(data_WADDR),
    .data_RADDR(data_RADDR),
    .data_Di(data_Di),
    .data_Do(data_Do),
    .axis_clk(clk),
    .axis_rst_n(~rst)
    );
    bram11 tap_RAM(
    .clk(clk),
    .we(tap_WE),
    .re(tap_RE),
    .waddr(tap_WADDR),
    .raddr(tap_RADDR),
    .wdi(tap_Di),
    .rdo(tap_Do)
    );
    bram11 data_RAM(
    .clk(clk),
    .we(data_WE),
    .re(data_RE),
    .waddr(data_WADDR),
    .raddr(data_RADDR),
    .wdi(data_Di),
    .rdo(data_Do)
    );
   
endmodule

module fir
#(  parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32,
    parameter Tape_Num    = 11
)
(
    // AXI-Lite AW channel
    output  wire                     awready,
    input   wire                     awvalid,
    input   wire [(pADDR_WIDTH-1):0] awaddr,
    // AXI-Lite W channel
    output  wire                     wready,
    input   wire                     wvalid,
    input   wire [(pDATA_WIDTH-1):0] wdata,
    // AXI-Lite AR channel
    output  reg                      arready,
    input   wire                     arvalid,
    input   wire [(pADDR_WIDTH-1):0] araddr,
    // AXI-Lite R channel
    input   wire                     rready,
    output  reg                      rvalid,
    output  wire [(pDATA_WIDTH-1):0] rdata,
    // AXI-Stream slave
    output  wire                     ss_tready,
    input   wire                     ss_tvalid,
    input   wire [(pDATA_WIDTH-1):0] ss_tdata,
    input   wire                     ss_tlast,
    // AXI-Stream master
    input   wire                     sm_tready,
    output  reg                      sm_tvalid,
    output  wire [(pDATA_WIDTH-1):0] sm_tdata,
    output  wire                     sm_tlast,
    // bram for tap RAM
    output  reg                      tap_WE,
    output  wire                     tap_RE,
    output  wire [(pADDR_WIDTH-1):0] tap_WADDR,
    output  wire [(pADDR_WIDTH-1):0] tap_RADDR,
    output  wire [(pDATA_WIDTH-1):0] tap_Di,
    input   wire [(pDATA_WIDTH-1):0] tap_Do,
    // bram for data RAM
    output  reg                      data_WE,
    output  wire                     data_RE,
    output  reg  [(pADDR_WIDTH-1):0] data_WADDR,
    output  reg  [(pADDR_WIDTH-1):0] data_RADDR,
    output  reg  [(pDATA_WIDTH-1):0] data_Di,
    input   wire [(pDATA_WIDTH-1):0] data_Do,

    input   wire                     axis_clk,
    input   wire                     axis_rst_n
);


// write transaction control signal: wready, awready
// wait for both write addr and write data then receive them at the same time
assign wready = wvalid & awvalid;
assign awready = wvalid & awvalid;
// read transaction control signal: arready
always @(*) begin
    // check if receiveing write request or rdata is received by master
    if((~wready)&(~awready)&(~rvalid))begin
        arready = arvalid;
    end
    else begin
        arready = 1'b0;
    end
end
reg _rvalid;
reg [1:0] _rdata_muxsel1, rdata_muxsel1;

reg [(pDATA_WIDTH-1):0] data_length, _data_length;
reg [(pDATA_WIDTH-1):0] rdata_reg, _rdata_reg;
reg [(pDATA_WIDTH-1):0] data_idx, _data_idx;
wire [(pADDR_WIDTH-1):0] config_tap_RADDR;

reg ap_start, _ap_start;
reg ap_idle, _ap_idle;
reg [1:0] ap_done, _ap_done;
wire write_req;
wire read_req;
wire write_req_start;
assign tap_RE = 1'b1;
assign data_RE = 1'b1;

assign write_req = wready & awready;
assign read_req = arready & arvalid;
assign write_req_start = write_req & wdata[0] & (awaddr==12'h00);

// rdata
assign rdata = _rdata_reg;
always @(*) begin
    case (rdata_muxsel1)
        2'b00: _rdata_reg = {2'b0,sm_tvalid,ss_tready,1'b0,ap_idle,ap_done[0],ap_start};
        2'b01: _rdata_reg = tap_Do;
        2'b10: _rdata_reg = data_length;
        2'b11: _rdata_reg = rdata_reg;
    endcase
end

assign tap_WADDR = {8'b0,awaddr[5:2]};
assign tap_Di = wdata;
assign config_tap_RADDR = {8'b0,araddr[5:2]};

// processing axi-lite write/read request
always @(*) begin
    if(write_req_start) _ap_start = 1'b1;
    else _ap_start = 1'b0; // ap_start only stays high for 1 cycle
end
always @(*) begin
    if(write_req&(awaddr==12'h10)) _data_length = wdata;
    else _data_length = data_length;
end
always @(*) begin
    if(write_req&awaddr[7])  tap_WE = 1'b1;
    else  tap_WE = 1'b0;
end
always @(*) begin
    _rvalid = rvalid;
    _rdata_muxsel1 = 2'b11;
    if((~write_req)&read_req)begin // read request
        _rvalid = 1'b1;
        if(araddr==12'h00)begin
            _rdata_muxsel1 = 2'b00;
        end
        else if(araddr==12'h10)begin // data length
            _rdata_muxsel1 = 2'b10;
        end
        else if(araddr[7])begin // 0x80: reading tap param
            _rdata_muxsel1 = 2'b01;
        end
    end
    else if(rvalid&rready) _rvalid = 1'b0; // stop asserting rvalid

end

// ap_idle
always @(*) begin
    _ap_idle = ap_idle;
    if(write_req_start)begin // start fir
        _ap_idle = 1'b0;
    end
    else if(data_idx==data_length)begin
        _ap_idle = 1'b1;
    end
end
// ap_done
// ap_done[1]: fir started
// ap_done[0]: fir finished transmittion
// 00->10->11->00
always @(*) begin
    _ap_done = ap_done;
    if(write_req_start)begin // start fir
        _ap_done = 2'b10;
    end
    else if(read_req && (ap_done==2'b11) && (araddr==12'h00))begin // read request
        _ap_done = 2'b00; // reset ap_done
    end
    else if((sm_tvalid==1'b0) && (data_idx==data_length) && ap_done[1] )begin // finish transmition
        _ap_done = 2'b11;
    end
end

// reg
always @(posedge axis_clk) begin
    if(~axis_rst_n)begin
        rvalid <= 1'b0;
        ap_start <= 1'b0;
        ap_idle  <= 1'b1;
        ap_done  <= 2'b00;
        data_length <= 0;
        rdata_reg <= 0;
        rdata_muxsel1 <= 1'b0;
    end
    else begin
        rvalid <= _rvalid;
        ap_start <= _ap_start;
        ap_idle  <= _ap_idle;
        ap_done  <= _ap_done;
        data_length <= _data_length;
        rdata_reg <= _rdata_reg;
        rdata_muxsel1 <= _rdata_muxsel1;
    end
end

reg [3:0] tap_idx, _tap_idx;
reg mul_data_in_sel, _mul_data_in_sel;
// fir engine
reg [(pDATA_WIDTH-1):0] acc, _acc, mul_out, ss_tdata_d;
reg stall;
wire acc_reset;
assign sm_tdata = _acc;
// avoid reading x from sram
always @(*) begin
    if( tap_idx > data_idx)begin
        _mul_data_in_sel = 1'b1;
    end
    else begin
        _mul_data_in_sel = 1'b0;
    end
end
always @(posedge axis_clk) begin
    mul_data_in_sel <= _mul_data_in_sel;
    ss_tdata_d <= ss_tdata;
end
always @(*) begin
    mul_out = (mul_data_in_sel ? 0 : ((tap_idx==4'd10)?ss_tdata_d:data_Do)) * tap_Do;
    _acc = (acc_reset ? 0 : acc) + (stall ? 0 : mul_out);
end
always @(posedge axis_clk) begin
    if(~axis_rst_n)begin
        acc <= 0;
    end
    else begin
        acc <= _acc;
    end
end

// sm stall
always @(*) begin
    if(({sm_tvalid,sm_tready}=={2'b10}||ss_tvalid==0))
        stall = 1'b1;
    else
        stall = 1'b0;
end
assign sm_tlast = (data_idx==data_length) ? sm_tvalid : 1'b0;

reg [3:0] data_A_shift, _data_A_shift;
reg _sm_tvalid;
assign acc_reset = (tap_idx==4'd9) ? 1'b1 : 1'b0;
assign ss_tready = (tap_idx==4'd0) ? 1'b1 : 1'b0;

always @(*) begin
    _tap_idx = tap_idx;
    _data_idx = data_idx;
    _data_A_shift = data_A_shift;
    if(~ap_idle)begin // check fir started
        case (tap_idx)
            4'd0: begin
                _tap_idx = 4'd10;
                _data_idx = data_idx + 1;
                _data_A_shift = (data_A_shift==4'd10) ? 4'd0 : data_A_shift + 1;
            end
            4'd10: begin
                if(stall) _tap_idx = 4'd10;
                else _tap_idx = 4'd9;
            end
            default: begin
                _tap_idx = tap_idx - 4'd1;
            end
        endcase
    end
    else begin
        if(_ap_start==1'b1)begin
            _tap_idx = 4'd10;
            _data_idx = 0;
            _data_A_shift = 4'd0;
        end
    end
end
// sm_tvalid
always @(*) begin
    _sm_tvalid = sm_tvalid;
    if((tap_idx==4'd0) && (ap_idle==1'b0))
        _sm_tvalid = 1'b1;
    else if(sm_tready & sm_tvalid)
        _sm_tvalid = 1'b0;
end
always @(posedge axis_clk) begin
    if(~axis_rst_n)begin
        tap_idx <= 4'd10;
        data_idx <= 0;
        sm_tvalid <= 1'b0;
        data_A_shift <= 4'd0;
    end
    else begin
        tap_idx <= _tap_idx;
        data_idx <= _data_idx;
        sm_tvalid <= _sm_tvalid;
        data_A_shift <= _data_A_shift;
    end
end

wire [(pADDR_WIDTH-1):0] fir_tap_RADDR;
assign fir_tap_RADDR = tap_idx;
assign tap_RADDR = ap_idle ? config_tap_RADDR : fir_tap_RADDR;


always @(*) begin
    data_Di = ss_tdata;
    data_WE = 1'b0;
    if(tap_idx==4'd0)begin //read in data
        data_WE = 1'b1;
    end
end
reg signed [5:0] data_ram_idx;
reg [3:0] idx_t;
always @(*) begin
    data_ram_idx = tap_idx - data_A_shift;
    idx_t = data_ram_idx + 4'd11;
    if(data_ram_idx>=0)
        data_RADDR = data_ram_idx;
    else
        data_RADDR = idx_t;
end
always @(*) begin
    data_WADDR = data_RADDR;
end
endmodule
	
`default_nettype wire
