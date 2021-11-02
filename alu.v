module alu
(
    // Входящие данные
    input  wire [3:0] ALU,      // Режим АЛУ
    input  wire [7:0] A,        // Значение src
    input  wire [7:0] B,        // Значение dst
    input  wire [7:0] P,        // Флаги на вход

    // Результат
    output wire [7:0] AR,       // Результат
    output reg  [7:0] AF        // Флаги
);

assign AR = R[7:0];

// Результат исполнения
reg  [8:0] R;

// Статусы ALU
wire zero  = (R[7:0] == 8'h00);
wire sign  =  R[7];
wire cout  =  R[8];
wire oadc  = (A[7] ^ B[7] ^ 1'b1) & (A[7] ^ R[7]); // Переполнение ADC
wire osbc  = (A[7] ^ B[7] ^ 1'b0) & (A[7] ^ R[7]); // Переполнение SBC
wire cin   =  P[0];

localparam
    ORA = 4'b0000, AND = 4'b0001, EOR = 4'b0010, ADC = 4'b0011,
    STA = 4'b0100, LDA = 4'b0101, CMP = 4'b0110, SBC = 4'b0111,
    ASL = 4'b1000, ROL = 4'b1001, LSR = 4'b1010, ROR = 4'b1011,
    BIT = 4'b1100, DEC = 4'b1101, INC = 4'b1110;

always @* begin

    // Расчет результата
    case (ALU)

        // Общие
        ORA: R = A | B;
        AND: R = A & B;
        EOR: R = A ^ B;
        ADC: R = A + B + cin;
        STA: R = A;
        LDA: R = B;
        CMP: R = A - B;
        SBC: R = A - B - !cin;

        // Сдвиги
        ASL: R = {B[6:0], 1'b0};
        ROL: R = {B[6:0], P[0]};
        LSR: R = {1'b0, B[7:1]};
        ROR: R = {P[0], B[7:1]};

        // Специальные
        BIT: R = A & B;
        DEC: R = B - 1;
        INC: R = B + 1;

    endcase

    // Расчет флагов
    casex (ALU)

        // ORA, AND, EOR, LDA, STA, INC, DEC
        4'b000x, 4'b0010,
        4'b010x, 4'b111x:
                    AF = {sign,        P[6:2], zero,  P[0]};
        ADC:        AF = {sign, oadc,  P[5:2], zero,  cout};
        CMP:        AF = {sign,        P[6:2], zero, ~cout};
        SBC:        AF = {sign, osbc,  P[5:2], zero, ~cout};
        ASL, ROL:   AF = {sign,        P[6:2], zero,  B[7]};
        LSR, ROR:   AF = {sign,        P[6:2], zero,  B[0]};
        BIT:        AF = {B[7:6],      P[5:2], zero,  P[0]};

    endcase

end

endmodule
