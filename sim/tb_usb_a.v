`timescale 1ns/1ps
module Gowin_OSC(output reg oscout=0,input oscen); always #9.52381 oscout=~oscout; endmodule
module Gowin_PLL(input clkin,mdclk,reset,output reg clkout0=0,output lock);
 always #41.666667 clkout0=~clkout0; assign lock=!reset; endmodule
module tb_usb_a;
 reg sys=0,rst=0; always #10 sys=~sys;
 tri dp,dm; pulldown(dp); pulldown(dm);
 wire tx,bck,ws,din,pa,led;
 reg key1=1;
 top dut(sys,rst,key1,dp,dm,bck,ws,din,pa,tx,led);
 defparam dut.u_key1.DEBOUNCE_CLKS=57;
 reg [63:0] injected=0; reg pulse=0; reg [1:0] kind=0;
 reg [63:0] frame; reg [7:0] octet; integer k,n,nonzero=0;
 task byte_rx; output [7:0] value; integer b; begin
 @(negedge tx); #542.857;
 if(tx!==0) $fatal(1,"start");
 for(b=0;b<8;b=b+1) begin #1085.714; value[b]=tx; end
 #1085.714; if(tx!==1) $fatal(1,"stop");
 end endtask
 task frames; input integer expect_sound; integer f,b; begin
 // Wait for a complete new frame, not a byte in the current frame.
 wait(dut.u_vofa.state==0); @(posedge dut.u_vofa.tx_start);
 // tx_start precedes the UART start edge by one clock.
 for(f=0;f<16;f=f+1) begin
 for(b=0;b<8;b=b+1) begin byte_rx(octet);frame[b*8+:8]=octet;end
 if(frame[63:32]!==32'h7f800000) $fatal(1,"framing");
 if(expect_sound==0 && frame[31:0]!==0) $fatal(1,"expected silence");
 if(frame[31:0]!=0) nonzero=nonzero+1;
 end
 end endtask
 task quiet; begin
 #200000;
 if(tx!==1 || dut.u_vofa.state!==0) $fatal(1,"not idle when disabled");
 #200000;
 if(tx!==1 || dut.u_vofa.state!==0) $fatal(1,"unexpected send");
 end endtask
 task send_report; input [63:0] data; begin
 @(negedge dut.usbclk); injected=data; pulse=1;
 @(negedge dut.usbclk); pulse=0;
 repeat(6) @(posedge dut.clk);
 end endtask
 initial begin
 #100;rst=1;
 wait(dut.usb_ready); repeat(10) @(posedge dut.usbclk);
 if(dut.typ!==0) $fatal(1,"host reset type");
 force dut.u_host.typ=kind;
 force dut.u_host.report=pulse;
 force dut.u_host.dbg_hid_report=injected;
 quiet;
 kind=1;
 for(k=2;k<8;k=k+1) begin
 send_report(64'h04 << (8*k));
 if(dut.a_down!==1) $fatal(1,"A in slot %d",k);
 end
 frames(1); if(nonzero<12) $fatal(1,"missing sine samples");
 send_report(64'h0101010101010000);
 if(dut.a_down!==1) $fatal(1,"rollover lost held state");
 send_report(0); if(dut.a_down!==0) $fatal(1,"release"); quiet;
 send_report(64'h0000000000040000); kind=0;
 repeat(10) @(posedge dut.usbclk);
 if(dut.a_down!==0) $fatal(1,"disconnect");
 quiet;
 key1=0; #20000; key1=1; #20000;
 if(dut.key1_enable!==1) $fatal(1,"KEY1 on");
 frames(1);
 key1=0; #20000;
 quiet;
 if(dut.key1_enable!==0) $fatal(1,"KEY1 off/hold repeated");
 key1=1; #20000;
 if(dut.u_vofa.dropped_frames!==0) $fatal(1,"dropped frames");
 $display("PASS USB reset, injected HID A all six positions, hold/release/rollover/disconnect, 32 decoded single-channel frames; KEY1 toggle/hold; JustFloat frames, sine and silence, zero drops");
 $finish;
 end
 initial begin #65000000; $fatal(1,"timeout"); end
endmodule