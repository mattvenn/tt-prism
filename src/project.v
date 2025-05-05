/*
 * Copyright (c) 2024 Uri Shaked
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_vga_example(
  input  wire [7:0] ui_in,    // Dedicated inputs
  output wire [7:0] uo_out,   // Dedicated outputs
  input  wire [7:0] uio_in,   // IOs: Input path
  output wire [7:0] uio_out,  // IOs: Output path
  output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
  input  wire       ena,      // always 1 when the design is powered, so you can ignore it
  input  wire       clk,      // clock
  input  wire       rst_n     // reset_n - low to reset
);

  // VGA signals
  wire hsync;
  wire vsync;
  wire [1:0] R;
  wire [1:0] G;
  wire [1:0] B;
  wire video_active;
  wire [9:0] pix_x;
  wire [9:0] pix_y;
  wire sound;

  // TinyVGA PMOD
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  // Unused outputs assigned to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;

  // Suppress unused signals warning
  wire _unused_ok = &{ena, ui_in, uio_in};

  reg [9:0] counter;

  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(pix_x),
    .vpos(pix_y)
  );
  
  wire [9:0] center_x = 10'd320;
  wire [9:0] center_y = 10'd240;

  wire [9:0] dist_x = (center_x < pix_x) ? (center_x - pix_x) : (pix_x - center_x);
  wire [9:0] dist_y = (center_y < pix_y) ? (center_y - pix_y) : (pix_y - center_y);

  wire [10:0] distance = dist_x + dist_y + counter;

  wire [1:0] diamond_color_r = {distance[0], distance[2]};
  wire [1:0] diamond_color_g = {distance[4], distance[7]};
  wire [1:0] diamond_color_b = {distance[6], distance[9]};

  wire is_diamond = ((dist_x + dist_y) > 10'd800 );

  wire [7:0] star_hash = (pix_x[7:0] ^ pix_y[7:0] ^ {pix_x[3:0], pix_y[3:0]}) + counter;
  wire is_star = (star_hash[7:3] == 0);
  wire [1:0] star_brightness = is_star ? star_hash[2:1]  : 2'b00;

  wire [1:0] final_r = is_diamond ? diamond_color_r : star_brightness;
  wire [1:0] final_g = is_diamond ? diamond_color_g : star_brightness;
  wire [1:0] final_b = is_diamond ? diamond_color_b : star_brightness;


  assign R = video_active ? final_r : 2'b00;
  assign G = video_active ? final_g : 2'b00;
  assign B = video_active ? final_b : 2'b00;
  
  
  always @(posedge vsync) begin
    if (~rst_n) begin
      counter <= 0;
    end else begin
      counter <= counter + 1;
    end
  end
  
endmodule
