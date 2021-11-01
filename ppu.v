module ppu
(
    input   wire        CLOCK,        
    output  reg  [3:0]  VGA_R,
    output  reg  [3:0]  VGA_G,
    output  reg  [3:0]  VGA_B,
    output  wire        VGA_HS,
    output  wire        VGA_VS,
    // Доступы к памяти
    output  reg  [9:0]  charmap_addr,
    output  reg  [9:0]  chardat_addr,
    input   wire [7:0]  charmap_ppu,
    input   wire [7:0]  chardat_ppu
);

// https://www.riyas.org/2013/12/online-led-matrix-font-generator-with.html       
// ---------------------------------------------------------------------
    
// Тайминги для горизонтальной развертки
parameter hz_visible = 640;
parameter hz_front   = 16;
parameter hz_sync    = 96;
parameter hz_back    = 48;
parameter hz_whole   = 800;

// Тайминги для вертикальной развертки
parameter vt_visible = 480;
parameter vt_front   = 10;
parameter vt_sync    = 2;
parameter vt_back    = 33;
parameter vt_whole   = 525;

// ---------------------------------------------------------------------
assign VGA_HS = x  < (hz_back + hz_visible + hz_front); // NEG
assign VGA_VS = y >= (vt_back + vt_visible + vt_front); // POS
// ---------------------------------------------------------------------

wire        xmax = (x == hz_whole - 1);
wire        ymax = (y == vt_whole - 1);
reg  [ 9:0] x    = 0;
reg  [ 9:0] y    = 0;
wire [ 9:0] X    = x - hz_back - 64 + 16; // X=[0..639]
wire [ 9:0] Y    = y - vt_back;           // Y=[0..479]
reg  [ 7:0] mask;

always @(posedge CLOCK) begin

    // Кадровая развертка
    x <= xmax ?         0 : x + 1;
    y <= xmax ? (ymax ? 0 : y + 1) : y;
    
    // Извлечение данных из знакогенератора
    case (X[3:0])
    
    4'h0: chardat_addr <= {Y[8:4], X[8:4]};
    4'h1: charmap_addr <= {chardat_ppu[7:0], Y[3:1]};
    4'hF: mask <= charmap_ppu;
    
    endcase

    // Вывод окна видеоадаптера
    if (x >= hz_back && x < hz_visible + hz_back && y >= vt_back && y < vt_visible + vt_back)
    begin
    
        if (x >= hz_back+64 && x < hz_back+64+512)
            {VGA_R, VGA_G, VGA_B} <= mask[ 3'h7 - X[3:1] ] ? 12'hCCC : 12'h000;
        else
            {VGA_R, VGA_G, VGA_B} <= 12'h111;
         
    end
    else {VGA_R, VGA_G, VGA_B} <= 12'b0;

end

endmodule