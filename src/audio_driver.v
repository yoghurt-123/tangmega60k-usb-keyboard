// Reworked official audio_drive: PT8211 16-bit right-justified stereo.
// WS=0 right, WS=1 left; same latched PCM sample in both channels.
// All logic runs on clk. DAC samples DIN on rising BCK; update on falling BCK.
module audio_drive #(parameter BCK_HALF_DIV = 17)(
    input clk, input rst_n, input [15:0] idata,
    output req, output reg HP_BCK, output reg HP_WS, output reg HP_DIN
);
    reg [15:0] divider;
    reg [4:0] bit_index;
    reg [15:0] frame_sample;
    wire [4:0] next_index = bit_index + 5'd1;
    wire falling_tick = (divider == BCK_HALF_DIV-1) && HP_BCK;
    assign req = rst_n && falling_tick && (bit_index == 31);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            divider <= 0;
            HP_BCK <= 0;
            HP_WS <= 1;
            HP_DIN <= 0;
            bit_index <= 31;
            frame_sample <= 0;
        end else if (divider == BCK_HALF_DIV-1) begin
            divider <= 0;
            HP_BCK <= ~HP_BCK;
            if (HP_BCK) begin
                bit_index <= next_index;
                HP_WS <= next_index[4];
                if (bit_index == 31) begin
                    frame_sample <= idata;
                    HP_DIN <= idata[15];
                end else begin
                    HP_DIN <= frame_sample[15-next_index[3:0]];
                end
            end
        end else divider <= divider + 1'b1;
    end
endmodule
