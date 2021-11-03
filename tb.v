`timescale 10ns / 1ns
module tb;
// ---------------------------------------------------------------------
reg             clock;
reg             clock_25;
reg             clock_50;
reg             intr;
// ---------------------------------------------------------------------
always  #0.5    clock    = ~clock;
always  #1.0    clock_50 = ~clock_50;
always  #2.0    clock_25 = ~clock_25;
// ---------------------------------------------------------------------
initial begin   intr = 0; clock = 0; clock_25 = 0; clock_50 = 0; #4 intr = 0; #2000 $finish; end
initial begin   $dumpfile("tb.vcd"); $dumpvars(0, tb); end
// ---------------------------------------------------------------------
reg     [ 7:0]  memory[65536];
// ---------------------------------------------------------------------
initial begin   $readmemh("tb.hex", memory, 0); end
// ---------------------------------------------------------------------
wire    [15:0]  address;
reg     [ 7:0]  i_data;
wire    [ 7:0]  o_data;
wire            we;
// ---------------------------------------------------------------------

// Контроллер блочной памяти
always @(posedge clock) begin

    i_data <= memory[ address ];
    if (we) memory[ address ] <= o_data;

end

// ---------------------------------------------------------------------

cpu CPUnit
(
    .clock      (clock_25),
    .resetn     (1'b1),
    .locked     (1'b1),
    .intr       (intr),
    .address    (address),
    .i_data     (i_data),
    .o_data     (o_data),
    .we         (we)
);

endmodule
