module marsohod2
(
    input   wire        clk,
    output  wire [3:0]  led,
    input   wire [1:0]  keys,
    output  wire        adc_clock_20mhz,
    input   wire [7:0]  adc_input,
    output  wire        sdram_clock,
    output  wire [11:0] sdram_addr,
    output  wire [1:0]  sdram_bank,
    inout   wire [15:0] sdram_dq,
    output  wire        sdram_ldqm,
    output  wire        sdram_udqm,
    output  wire        sdram_ras,
    output  wire        sdram_cas,
    output  wire        sdram_we,
    output  wire [4:0]  vga_r,
    output  wire [5:0]  vga_g,
    output  wire [4:0]  vga_b,
    output  wire        vga_hs,
    output  wire        vga_vs,
    input   wire        ftdi_rx,
    output  wire        ftdi_tx,
    input   wire [3:0]  k4,
    output  wire [7:0]  hex,
    output  wire [3:0]  en7
);

// Генерация частот
// -----------------------------------------------------------------------------

wire locked;
wire clock_25;

pll unit_pll
(
    .clk       (clk),
    .m25       (clock_25),
    .locked    (locked)
);

// -----------------------------------------------------------------------------

ppu PPUModule
(
    // Физический интерфейс
    .CLOCK          (clock_25),
    .VGA_R          (vga_r[4:1]),
    .VGA_G          (vga_g[5:2]),
    .VGA_B          (vga_b[4:1]),
    .VGA_HS         (vga_hs),
    .VGA_VS         (vga_vs),
    // Доступы к памяти
    .charmap_addr   (charmap_addr),
    .chardat_addr   (chardat_addr),
    .charmap_ppu    (charmap_ppu),
    .chardat_ppu    (chardat_ppu),
);

// Объявление областей памяти
// -----------------------------------------------------------------------------

// Из обрабатывающего процессора
wire [15:0] address;            
wire [ 7:0] data_w;             // Данные на запись
wire        charmap_we;         // Сигнал записи в charmap
wire        chardat_we;         // Сигнал записи в chardata
wire [ 7:0] charmap_cpu;        // Данные на вход в процессор
wire [ 7:0] chardat_cpu;        // Данные на вход в процессор

// Для PPU
wire [ 9:0] charmap_addr;
wire [ 7:0] charmap_ppu;
wire [ 9:0] chardat_addr;
wire [ 7:0] chardat_ppu;

// Двухпортовая память для знакогенератора
charmap UnitCharmap
(
    .clock     (clk),

    // Для процессора
    .address_a (address[9:0]),
    .q_a       (charmap_cpu),
    .data_a    (data_w),
    .wren_a    (charmap_we),

    // Для видеоадаптера
    .address_b (charmap_addr),
    .q_b       (charmap_ppu),
);

// Двухпортовая память для хранения chars
chardata UnitChardata
(
    .clock     (clk),

    // Для процессора
    .address_a (address[9:0]),
    .q_a       (chardat_cpu),
    .data_a    (data_w),
    .wren_a    (chardat_we),

    // Для видеоадаптера
    .address_b (chardat_addr),
    .q_b       (chardat_ppu),
);

// Объявление процессорного модуля
// -----------------------------------------------------------------------------

endmodule

`include "../ppu.v"
