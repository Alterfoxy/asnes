// Все регистры в процессоре
// ---------------------------------------------------------------------
reg  [ 7:0] A           = 8'h00;    // Аккумулятор
reg  [ 7:0] X           = 8'hF0;    // Индексный X
reg  [ 7:0] Y           = 8'hFF;    // Индексный Y
reg  [ 7:0] S           = 8'h00;    // Стек
reg  [ 7:0] P           = 8'h00;    // Флаги
reg  [15:0] pc          = 16'h0000; // Счетчик инструкции
// ---------------------------------------------------------------------
reg  [ 4:0] T           = 5'h0;     // 0..31 Текущая линия выполнения на верилог
reg         sel         = 1'b0;     // Выбор источника адреса в память
reg  [15:0] cursor      = 16'h0000; // Указатель в память
reg  [ 7:0] opcode      = 8'h00;    // Сохраненный опкод
reg  [ 7:0] tmpb        = 8'h00;    // Временный байт
reg         intp        = 1'b0;     // Предыдущий INTR
// ---------------------------------------------------------------------
wire [ 3:0] branch      = {P[1], P[0], P[6], P[7]}; // Z,C,V,N
wire [ 7:0] azpx        = i_data + X;
wire [ 7:0] azpy        = i_data + Y;
wire [ 7:0] inx         = X + 1'b1;
wire [ 7:0] iny         = Y + 1'b1;
wire [ 7:0] dex         = X - 1'b1;
wire [ 7:0] dey         = Y - 1'b1;
wire [ 7:0] sinc        = S + 1'b1;
wire [ 7:0] cursor8     = cursor + 1'b1;
// ---------------------------------------------------------------------
wire [ 7:0] alu_r;      // Результат вычисления
wire [ 7:0] alu_p;      // Результирующий флаг
reg  [ 3:0] alu         = 4'h0;     // Выбор АЛУ
reg  [ 1:0] src         = 2'b0;     // 0-Acc, 1-X, 2-Y
wire [ 7:0] src_mux     = src == 2'b00 ? A :
                          src == 2'b01 ? X :
                          src == 2'b10 ? Y : 1'b0;
// ---------------------------------------------------------------------

initial begin we = 1'b0; end

localparam
    RST     = 0,
    ZP      = 1,
    ZPX     = 2,
    ZPY     = 3,
    ABS     = 4,  // 5
    ABX     = 6,  // 7
    ABY     = 8,  // 9
    NDX     = 10, // 11,12
    NDY     = 13, // 14,15
    REL     = 16, // 10h
    IMM     = 17, // 11h
    IMP     = 18, // 12h Исполнение инструкции
    WEND    = 19,
    TCK1    = 20,
    TCK2    = 21,
    // Обработка прерывания
    BRK1    = 22,
    BRK2    = 23,
    BRK3    = 24,
    BRK4    = 25,
    BRK5    = 26,
    BRK6    = 27;

// ---------------------------------------------------------------------
// Арифметико-логичекое устройство
// ---------------------------------------------------------------------

alu ALUModule
(
    .ALU    (alu),
    .A      (src_mux),
    .B      (i_data),
    .P      (P),
    .AR     (alu_r),
    .AF     (alu_p)
);
