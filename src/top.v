// USB HID host adapted from Sipeed's referenced example; 60K PLL and pinout.
module top(input sys_clk, input rst_n, input key1, inout usb_dp, inout usb_dm,
 output HP_BCK, HP_WS, HP_DIN, PA_EN, UART_TX, WS2812_DATA);
 wire clk;
 Gowin_OSC u_osc(.oscout(clk),.oscen(1'b1));
 reg [15:0] startup=0;
 reg [1:0] reset_sync=0;
 always @(posedge clk or negedge rst_n)
  if(!rst_n) reset_sync<=0; else reset_sync<={reset_sync[0],1'b1};
 always @(posedge clk)
  if(!reset_sync[1]) startup<=0; else if(!(&startup)) startup<=startup+1'b1;
 wire ready=&startup;
 wire usbclk, locked;
 Gowin_PLL u_usb_pll(.clkin(sys_clk),.clkout0(usbclk),.lock(locked),
 .mdclk(sys_clk),.reset(!ready));
 reg [15:0] usb_start=0;
 always @(posedge usbclk or negedge locked)
  if(!locked) usb_start<=0;
  else if(!ready) usb_start<=0;
  else if(!(&usb_start)) usb_start<=usb_start+1'b1;
 wire usb_ready=&usb_start;
 wire [1:0] typ;
 wire report, conerr;
 wire [63:0] raw;
 usb_hid_host u_host(.usbclk(usbclk),.usbrst_n(usb_ready),
 .usb_dp(usb_dp),.usb_dm(usb_dm),.typ(typ),.report(report),
 .conerr(conerr),.dbg_hid_report(raw),
 .key_modifiers(),.key1(),.key2(),.key3(),.key4(),
 .mouse_btn(),.mouse_dx(),.mouse_dy(),
 .game_l(),.game_r(),.game_u(),.game_d(),.game_a(),.game_b(),
 .game_x(),.game_y(),.game_sel(),.game_sta());
 wire held_usb;
 usb_a_key u_key(.clk(usbclk),.rst_n(usb_ready),.typ(typ),.report(report),.raw(raw),.held(held_usb));
 // Only stable single-bit states cross domains, each through two registers.
 reg [1:0] held_sync=0, lock_sync=0, keyboard_sync=0;
 always @(posedge clk) begin
  if(!ready) begin held_sync<=0; lock_sync<=0; keyboard_sync<=0; end
  else begin
   held_sync<={held_sync[0],held_usb};
   lock_sync<={lock_sync[0],locked};
   keyboard_sync<={keyboard_sync[0],typ==1};
  end
 end
 wire a_down=held_sync[1] && keyboard_sync[1] && lock_sync[1];
 wire key1_enable;
 key_toggle u_key1(.clk(clk),.rst_n(ready),.key_n(key1),.enable(key1_enable));
 wire tone_enable=key1_enable | a_down;
 wire sample_tick;
 wire signed [15:0] sine_pcm;
 wire signed [15:0] pcm=sine_pcm;
 rom_save_sin u_tone(.clk(clk),.rst_n(ready),.sample_tick(sample_tick),.data(sine_pcm));
 audio_drive #(.BCK_HALF_DIV(17)) u_audio(.clk(clk),.rst_n(ready),.idata(pcm),
 .req(sample_tick),.HP_BCK(HP_BCK),.HP_WS(HP_WS),.HP_DIN(HP_DIN));
 assign PA_EN=!ready;
 vofa_uart u_vofa(.clk(clk),.rst_n(ready),.enable(tone_enable),.sample_tick(sample_tick),
 .pcm(pcm),.uart_tx_pin(UART_TX),.dropped_frames());
 // Green: awaiting keyboard; blue: keyboard recognized; purple: A held.
 status_led u_led(.clk(clk),.rst_n(ready),
 .color_sel(a_down ? 2'd2 : (keyboard_sync[1] ? 2'd1 : 2'd0)),.led_data(WS2812_DATA));
endmodule
