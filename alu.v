module alu
(
    // Входящие данные
    input  wire [3:0] ALU,      // Режим АЛУ
    input  wire [7:0] A,        // Значение src
    input  wire [7:0] B,        // Значение dst
    input  wire [7:0] P,        // Флаги на вход
    input  wire [7:0] opcode,

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

always @* begin

    // Расчет результата
    case (ALU)

        // Общие
        /* ORA */ 4'b0000: R = A | B;
        /* AND */ 4'b0001: R = A & B;
        /* EOR */ 4'b0010: R = A ^ B;
        /* ADC */ 4'b0011: R = A + B + cin;
        /* STA */ 4'b0100: R = A;
        /* LDA */ 4'b0101: R = B;
        /* CMP */ 4'b0110: R = A - B;
        /* SBC */ 4'b0111: R = A - B - !cin;

        // Сдвиги
        /* ASL */ 4'b1000: R = {B[6:0], 1'b0};
        /* ROL */ 4'b1001: R = {B[6:0], P[0]};
        /* LSR */ 4'b1010: R = {1'b0, B[7:1]};
        /* ROR */ 4'b1011: R = {P[0], B[7:1]};

        // Специальные
        /* BIT */ 4'b1100: R = A & B;
        /* DEC */ 4'b1101: R = B - 1;
        /* INC */ 4'b1110: R = B + 1;

    endcase

    // Расчет флагов
    casex (ALU)

        // ORA, AND, EOR, LDA, STA, INC, DEC
        4'b000x, 4'b0010, 4'b010x, 4'b111x:
                                 AF = {sign,        P[6:2], zero, P[0]};
        /* ADC */       4'b0011: AF = {sign, oadc,  P[5:2], zero,  cout};
        /* CMP */       4'b0110: AF = {sign,        P[6:2], zero, ~cout};
        /* SBC */       4'b0111: AF = {sign, osbc,  P[5:2], zero, ~cout};
        /* ASL, ROL */  4'b100x: AF = {sign,        P[6:2], zero,  B[7]};
        /* LSR, ROR */  4'b101x: AF = {sign,        P[6:2], zero,  B[0]};

        // BIT
        4'b1100: AF = {B[7:6], P[5:2], zero, P[0]};

    endcase

end

endmodule
