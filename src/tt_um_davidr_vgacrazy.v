/*
 * Geometry Dash para Tiny Tapeout / VGA 640x480
 * Basado en los ejemplos VGA de Uri Shaked y Renaldas Zioma
 * SPDX-License-Identifier: Apache-2.0
 *
 * ui_in[0] = saltar (un salto al presionar y otro al soltar)
 */

`default_nettype none

module tt_um_davidr_vgacrazy(
  input  wire [7:0] ui_in,    // Dedicated inputs
  output wire [7:0] uo_out,   // Dedicated outputs
  input  wire [7:0] uio_in,   // IOs: Input path
  output wire [7:0] uio_out,  // IOs: Output path
  output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
  input  wire       ena,      // always 1 when the design is powered, so you can ignore it
  input  wire       clk,      // clock (25.175 MHz)
  input  wire       rst_n     // reset_n - low to reset
);

  // ------------------------------------------------------------------
  // VGA
  // ------------------------------------------------------------------
  wire hsync;
  wire vsync;
  wire [1:0] R;
  wire [1:0] G;
  wire [1:0] B;
  wire video_active;
  wire [9:0] pix_x;
  wire [9:0] pix_y;

  // TinyVGA PMOD
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  assign uio_out = 0;
  assign uio_oe  = 0;

  wire _unused_ok = &{ena, ui_in[7:1], uio_in};

  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(pix_x),
    .vpos(pix_y)
  );

  // ------------------------------------------------------------------
  // Geometria
  // ------------------------------------------------------------------
  // Casillas de 32 px. Suelo en y = 384 (fila 12). Cubo fijo en x = 128..159.
  // El mundo avanza 5 px por frame; el nivel mide 256 casillas y se repite.
  // Salto: 66 px de alto, 23 frames (115 px = 3.6 casillas).
  localparam [4:0] DEAD_TIME = 5'd31;

  // ------------------------------------------------------------------
  // Boton: un salto por cada flanco (al presionar y al soltar)
  // ------------------------------------------------------------------
  reg [2:0] btn;
  always @(posedge clk) btn <= {btn[1:0], ui_in[0]};
  wire btn_edge = btn[1] ^ btn[2];

  wire frame_tick = (pix_x == 10'd0) && (pix_y == 10'd480);

  // ------------------------------------------------------------------
  // Estado
  // ------------------------------------------------------------------
  reg [12:0] scroll;       // posicion en el nivel (px)
  reg [7:0]  h;            // altura del cubo sobre el suelo (px)
  reg signed [4:0] vel;    // velocidad vertical (+ = sube)
  reg        on_ground;
  reg [6:0]  angle;        // [6:5] cuadrante, [4:1] indice de la LUT, [0] fraccion
  reg [4:0]  dead;         // contador de muerte (0 = vivo)
  reg        hit;          // colision detectada en este frame
  reg        press;        // se pulso el boton durante este frame
  reg [1:0]  bh_l, bh_r;   // altura de bloques bajo el cubo en el proximo frame

  // ------------------------------------------------------------------
  // Nivel: col = {pico, altura de la pila de bloques (0..3)}
  // ------------------------------------------------------------------
  wire [12:0] world_x = {3'b000, pix_x} + scroll;
  wire [7:0]  tile    = world_x[12:5];
  wire [4:0]  tx      = world_x[4:0];
  wire [4:0]  row     = pix_y[9:5];
  wire [4:0]  ty      = pix_y[4:0];

  reg [2:0] col;
  always @(*) begin
    case (tile)
      8'd12: col = 3'b1_00;
      8'd24: col = 3'b1_00;
      8'd25: col = 3'b1_00;
      8'd36: col = 3'b1_00;
      8'd42: col = 3'b0_01;
      8'd48: col = 3'b1_00;
      8'd54: col = 3'b0_01;
      8'd64: col = 3'b0_01;
      8'd65: col = 3'b1_00;
      8'd66: col = 3'b1_00;
      8'd67: col = 3'b0_10;
      8'd68: col = 3'b1_00;
      8'd69: col = 3'b1_00;
      8'd70: col = 3'b0_11;
      8'd71: col = 3'b0_11;
      8'd72: col = 3'b0_11;
      8'd73: col = 3'b0_11;
      8'd74: col = 3'b0_11;
      8'd75: col = 3'b0_11;
      8'd76: col = 3'b0_11;
      8'd84: col = 3'b1_00;
      8'd85: col = 3'b1_00;
      8'd90: col = 3'b0_01;
      8'd94: col = 3'b1_00;
      8'd96: col = 3'b0_01;
      8'd102: col = 3'b0_01;
      8'd103: col = 3'b1_00;
      8'd104: col = 3'b1_00;
      8'd105: col = 3'b1_00;
      8'd106: col = 3'b0_01;
      8'd107: col = 3'b1_00;
      8'd108: col = 3'b1_00;
      8'd109: col = 3'b1_00;
      8'd110: col = 3'b0_01;
      8'd120: col = 3'b0_01;
      8'd121: col = 3'b0_01;
      8'd122: col = 3'b0_01;
      8'd123: col = 3'b0_01;
      8'd124: col = 3'b1_00;
      8'd125: col = 3'b1_00;
      8'd126: col = 3'b0_10;
      8'd127: col = 3'b0_10;
      8'd128: col = 3'b0_10;
      8'd129: col = 3'b0_10;
      8'd130: col = 3'b1_00;
      8'd131: col = 3'b1_00;
      8'd132: col = 3'b0_11;
      8'd133: col = 3'b0_11;
      8'd134: col = 3'b0_11;
      8'd135: col = 3'b0_11;
      8'd140: col = 3'b1_00;
      8'd146: col = 3'b1_00;
      8'd147: col = 3'b1_00;
      8'd152: col = 3'b0_01;
      8'd153: col = 3'b1_00;
      8'd154: col = 3'b1_00;
      8'd155: col = 3'b1_00;
      8'd156: col = 3'b0_10;
      8'd157: col = 3'b1_00;
      8'd158: col = 3'b1_00;
      8'd159: col = 3'b1_00;
      8'd160: col = 3'b0_11;
      8'd161: col = 3'b1_00;
      8'd162: col = 3'b1_00;
      8'd163: col = 3'b1_00;
      8'd164: col = 3'b0_11;
      8'd172: col = 3'b1_00;
      8'd173: col = 3'b1_00;
      8'd177: col = 3'b0_01;
      8'd178: col = 3'b0_01;
      8'd179: col = 3'b0_01;
      8'd180: col = 3'b0_01;
      8'd181: col = 3'b1_01;
      8'd182: col = 3'b0_01;
      8'd183: col = 3'b0_01;
      8'd184: col = 3'b0_01;
      8'd185: col = 3'b0_01;
      8'd192: col = 3'b1_00;
      8'd195: col = 3'b1_00;
      8'd196: col = 3'b1_00;
      8'd203: col = 3'b0_01;
      8'd204: col = 3'b1_00;
      8'd205: col = 3'b1_00;
      8'd206: col = 3'b0_10;
      8'd207: col = 3'b1_00;
      8'd208: col = 3'b1_00;
      8'd209: col = 3'b0_10;
      8'd210: col = 3'b1_00;
      8'd211: col = 3'b1_00;
      8'd212: col = 3'b0_01;
      8'd218: col = 3'b1_00;
      8'd219: col = 3'b1_00;
      8'd224: col = 3'b1_00;
      default: col = 3'b0_00;
    endcase
  end

  wire [1:0] bh        = col[1:0];
  wire       col_spike = col[2];
  wire [4:0] top_row   = 5'd12 - {3'b000, bh};

  wire block_pix  = (row >= top_row) && (row < 5'd12);
  wire block_edge = (tx == 5'd0) || (tx == 5'd31) || (ty == 5'd0) || (ty == 5'd31);

  // Pico (triangulo) sobre la pila; d = distancia al centro de la casilla
  wire [3:0] d          = tx[4] ? tx[3:0] : ~tx[3:0];
  wire [3:0] half_w     = ty[4:1];
  wire       spike_here = col_spike && (row + 5'd1 == top_row);
  wire       spike_pix  = spike_here && (d <= half_w);
  wire       spike_edge = (d == half_w) || (ty[4:1] == 4'd15);
  // hitbox mas pequena que el dibujo
  wire       spike_core = spike_here && (({1'b0, d} + 5'd4) <= {1'b0, half_w});

  // ------------------------------------------------------------------
  // Fisica (una vez por frame)
  // ------------------------------------------------------------------
  wire [1:0] floor_b  = (bh_l > bh_r) ? bh_l : bh_r;
  wire [7:0] floor_px = {1'b0, floor_b, 5'b00000};
  wire [8:0] hn       = {1'b0, h} + {{4{vel[4]}}, vel};
  wire       falling  = vel[4] || (vel == 5'sd0);
  wire       lands    = falling && (h >= floor_px) && (hn[8] || (hn[7:0] <= floor_px));
  wire       standing = on_ground && (h == floor_px);

  // hitbox del cubo: siempre el cuadrado sin rotar
  wire [9:0] py_full = pix_y + {2'b00, h} - 10'd352;
  wire       hitbox  = (pix_x[9:5] == 5'd4) && (py_full[9:5] == 5'd0);
  wire       collide = video_active && hitbox && (spike_core || block_pix);

  always @(posedge clk) begin
    if (~rst_n) begin
      scroll    <= 0;
      h         <= 0;
      vel       <= 0;
      on_ground <= 1'b1;
      angle     <= 0;
      dead      <= 0;
      hit       <= 0;
      press     <= 0;
      bh_l      <= 0;
      bh_r      <= 0;
    end else begin
      // columnas que quedaran bajo el cubo tras avanzar 5 px
      if (pix_x == 10'd133) bh_l <= bh;
      if (pix_x == 10'd164) bh_r <= bh;

      if (btn_edge)        press <= 1'b1;
      else if (frame_tick) press <= 1'b0;

      if (frame_tick)   hit <= 1'b0;
      else if (collide) hit <= 1'b1;

      if (frame_tick) begin
        if (dead != 0) begin
          dead <= dead - 5'd1;
          if (dead == 5'd1) begin   // reinicia el nivel
            scroll    <= 0;
            h         <= 0;
            vel       <= 0;
            on_ground <= 1'b1;
            angle     <= 0;
          end
        end else if (hit) begin
          dead <= DEAD_TIME;
        end else begin
          scroll <= scroll + 13'd5;
          if (standing) begin
            if (press) begin
              h         <= h + 8'd11;
              vel       <= 5'sd10;
              on_ground <= 1'b0;
              angle     <= angle + 7'd3;
            end
          end else if (lands) begin
            h         <= floor_px;
            vel       <= 0;
            on_ground <= 1'b1;
            angle     <= {angle[6:5] + {1'b0, angle[4]}, 5'b00000};  // al cuadrante mas cercano
          end else begin
            h         <= hn[7:0];
            vel       <= (vel == -5'sd15) ? vel : vel - 5'sd1;
            on_ground <= 1'b0;
            angle     <= angle + 7'd3;
          end
        end
      end
    end
  end

  // ------------------------------------------------------------------
  // Cubo rotado: coordenadas de textura por DDA (sin multiplicadores)
  //   a =  c*u + s*v      b = -s*u + c*v      (u,v relativos al centro)
  // ------------------------------------------------------------------
  function [5:0] sin_lut(input [4:0] k);   // 32*sin(k * 5.625 grados)
    begin
      case (k)
        5'd0: sin_lut = 6'd0;
        5'd1: sin_lut = 6'd3;
        5'd2: sin_lut = 6'd6;
        5'd3: sin_lut = 6'd9;
        5'd4: sin_lut = 6'd12;
        5'd5: sin_lut = 6'd15;
        5'd6: sin_lut = 6'd18;
        5'd7: sin_lut = 6'd20;
        5'd8: sin_lut = 6'd23;
        5'd9: sin_lut = 6'd25;
        5'd10: sin_lut = 6'd27;
        5'd11: sin_lut = 6'd28;
        5'd12: sin_lut = 6'd30;
        5'd13: sin_lut = 6'd31;
        5'd14: sin_lut = 6'd31;
        5'd15: sin_lut = 6'd32;
        5'd16: sin_lut = 6'd32;
        default: sin_lut = 6'd32;
      endcase
    end
  endfunction

  wire [5:0] rs = sin_lut({1'b0, angle[4:1]});
  wire [5:0] rc = sin_lut(5'd16 - {1'b0, angle[4:1]});

  // caja de 48 x 48 centrada en el cubo
  wire [9:0] bv      = pix_y + {2'b00, h} - 10'd344;
  wire       in_rows = (bv < 10'd48);
  wire       in_cols = (pix_x >= 10'd120) && (pix_x < 10'd168);

  wire signed [11:0] sum_cs  = {6'b0, rc} + {6'b0, rs};
  wire signed [11:0] diff_sc = {6'b0, rs} - {6'b0, rc};

  reg signed [11:0] a_row, b_row, a, b;
  always @(posedge clk) begin
    if (pix_y == 10'd0 && pix_x == 10'd0) begin
      a_row <= -((sum_cs <<< 4) + (sum_cs <<< 3));     // -24*(c+s)
      b_row <=  (diff_sc <<< 4) + (diff_sc <<< 3);     //  24*(s-c)
    end else if (in_rows && pix_x == 10'd168) begin
      a_row <= a_row + $signed({6'b0, rs});
      b_row <= b_row + $signed({6'b0, rc});
    end
    if (pix_x == 10'd119) begin
      a <= a_row;
      b <= b_row;
    end else if (in_cols) begin
      a <= a + $signed({6'b0, rc});
      b <= b - $signed({6'b0, rs});
    end
  end

  wire a_in = (a[11:9] == 3'b000) || (a[11:9] == 3'b111);
  wire b_in = (b[11:9] == 3'b000) || (b[11:9] == 3'b111);
  wire player_pix = in_rows && in_cols && a_in && b_in;

  wire [4:0] ta = {~a[9], a[8:5]};
  wire [4:0] tb = {~b[9], b[8:5]};
  // cuartos de vuelta completos
  wire [4:0] px = (angle[6:5] == 2'd0) ?  ta :
                  (angle[6:5] == 2'd1) ?  tb :
                  (angle[6:5] == 2'd2) ? ~ta : ~tb;
  wire [4:0] py = (angle[6:5] == 2'd0) ?  tb :
                  (angle[6:5] == 2'd1) ? ~ta :
                  (angle[6:5] == 2'd2) ? ~tb :  ta;

  wire p_border = (px < 5'd3) || (px > 5'd28) || (py < 5'd3) || (py > 5'd28);
  wire p_eye    = (py[4:3] == 2'b01)  && ((px[4:2] == 3'b010) || (px[4:2] == 3'b101));
  wire p_mouth  = (py[4:2] == 3'b101) && (px[4:3] == 2'b01 || px[4:3] == 2'b10);

  wire [5:0] player_color = p_border           ? 6'b00_00_00 :
                            (p_eye || p_mouth) ? 6'b00_11_11 :
                                                 6'b11_11_00;

  // ------------------------------------------------------------------
  // Suelo, fondo y barra de progreso
  // ------------------------------------------------------------------
  wire ground      = (pix_y >= 10'd384);
  wire ground_line = (pix_y[9:1] == 9'd192);
  wire ground_grid = (tx == 5'd0) || (ty == 5'd0);

  wire [9:0] bg_x    = pix_x + scroll[11:2];           // parallax
  wire       sky_chk = bg_x[6] ^ pix_y[6];

  wire [9:0] prog_w   = {1'b0, scroll[12:4]} + {3'b000, scroll[12:6]};  // 0..638
  wire       progress = (pix_y < 10'd8) && (pix_x < prog_w);

  wire is_dead = (dead != 5'd0);

  wire [5:0] sky_color = is_dead ? (dead[2] ? 6'b10_00_00 : 6'b01_00_00) :
                         sky_chk ? 6'b01_00_11 : 6'b01_00_10;

  wire [5:0] color =
      (player_pix && !is_dead) ? player_color :
      spike_pix                ? (spike_edge ? 6'b11_11_11 : 6'b00_00_00) :
      block_pix                ? (block_edge ? 6'b11_11_11 : 6'b00_00_01) :
      ground_line              ? 6'b11_11_11 :
      ground                   ? (ground_grid ? 6'b00_01_10 : 6'b00_00_01) :
      progress                 ? 6'b00_11_00 :
                                 sky_color;

  assign {R, G, B} = video_active ? color : 6'b00_00_00;

endmodule
