module cpu
(
    // Стандартный интерфейс обмена данными с внешним
    input   wire            clock,      // 25 mhz
    input   wire            resetn,     // 1 то работает процессор
    input   wire            locked,     // 1 если разрешено выполнять логику
    output  wire    [15:0]  address,
    input   wire    [ 7:0]  i_data,
    output  reg     [ 7:0]  o_data,
    output  reg             we          // we-разрешение записи
);

assign address = sel ? cursor : pc;

`include "decl.v"

always @(posedge clock)
if (resetn == 1'b0) begin pc <= 1'b0; T <= 1'b0; sel <= 1'b0; end
else if (locked == 1'b1)
case (T)

    // Маршрутизация опкода
    // ---------------------------------------------------------------------
    RST: begin

        src <= 1'b0; // acc
        dst <= 1'b0; // i_data
        alu <= i_data[7:5];

        // Декодирование операнда
        casex (i_data)
        8'bxxx_000_x1: T <= NDX;
        8'bxxx_010_x1,
        8'b1xx_000_x0: T <= IMM;
        8'bxxx_100_x1: T <= NDY;
        8'bxxx_110_x1: T <= ABY;
        8'bxxx_001_xx: T <= ZP;
        8'bxxx_011_xx,
        8'b001_000_00: T <= ABS;
        8'b10x_101_1x: T <= ZPY;
        8'bxxx_101_xx: T <= ZPX;
        8'b10x_111_1x: T <= ABY;
        8'bxxx_111_xx: T <= ABX;
        8'bxxx_100_00: T <= REL;
        8'b0xx_010_10: T <= IMP; // ACC
        default:       T <= IMP;
        endcase

        pc     <= pc + 1'b1;
        opcode <= i_data;

        // Обработка некоторых опкодов
        casex (i_data)

        // Флаги
        /* CLC */ 8'h18: begin T <= RST; P[0] <= 1'b0; end
        /* SEC */ 8'h38: begin T <= RST; P[0] <= 1'b1; end
        /* CLI */ 8'h58: begin T <= RST; P[2] <= 1'b0; end
        /* SEI */ 8'h78: begin T <= RST; P[2] <= 1'b1; end
        /* CLV */ 8'hB8: begin T <= RST; P[6] <= 1'b0; end
        /* CLD */ 8'hD8: begin T <= RST; P[3] <= 1'b0; end
        /* SED */ 8'hF8: begin T <= RST; P[3] <= 1'b1; end

        // Пересылка
        /* TYA */ 8'h98: begin T <= RST; A <= Y; P <= {Y[7], P[6:2], Y==0, P[0]}; end
        /* TAY */ 8'hA8: begin T <= RST; Y <= A; P <= {A[7], P[6:2], A==0, P[0]}; end
        /* TXA */ 8'h8A: begin T <= RST; A <= X; P <= {X[7], P[6:2], X==0, P[0]}; end
        /* TAX */ 8'hAA: begin T <= RST; X <= A; P <= {A[7], P[6:2], A==0, P[0]}; end
        /* TSX */ 8'hBA: begin T <= RST; X <= S; P <= {S[7], P[6:2], S==0, P[0]}; end
        /* TXS */ 8'h9A: begin T <= RST; S <= X; end
        /* NOP */ 8'hEA, 8'h1A, 8'h3A, 8'h5A, 8'h7A, 8'hDA, 8'hFA: T <= RST;

        // Выбор АЛУ
        /* LDXY*/ 8'hA0, 8'hA4, 8'hAC, 8'hB4, 8'hBC,
                  8'hA2, 8'hA6, 8'hAE, 8'hB6, 8'hBE: alu <= /* LDA */ 4'b0101;
        /* CPX */ 8'hE0, 8'hE4, 8'hEC: begin alu <= /* CMP */ 4'b0110; src <= 2'h1; end
        /* CPY */ 8'hC0, 8'hC4, 8'hCC: begin alu <= /* CMP */ 4'b0110; src <= 2'h2; end

        // Однотактовая работа сдвиговых инструкции
        /* ASL */ 8'h0A: begin A <= {A[6:0], 1'b0}; P <= {A[6], P[6:2],  A[6:0]==0,       A[7]}; T <= RST; end
        /* ROL */ 8'h2A: begin A <= {A[6:0], P[0]}; P <= {A[6], P[6:2], {A[6:0],P[0]}==0, A[7]}; T <= RST; end
        /* LSR */ 8'h4A: begin A <= {1'b0, A[7:1]}; P <= {1'b0, P[6:2],  A[7:1]==0,       A[0]}; T <= RST; end
        /* ROR */ 8'h6A: begin A <= {P[0], A[7:1]}; P <= {P[0], P[6:2], {P[0],A[7:1]}==0, A[0]}; T <= RST; end

        // ASL, ROL, LSR, ROR Memory
        8'b0xx_xxx10: begin alu <= {1'b1, i_data[7:5]}; end
        endcase

    end

    // -----------------------------------------------------------------

    // Извлечение адреса на операнд
    ZP:     begin T <= IMP;   pc <= pc + 1; cursor <= {8'h00, i_data};   sel <= 1'b1; end
    ZPX:    begin T <= IMP;   pc <= pc + 1; cursor <= {8'h00, azpx};     sel <= 1'b1; end
    ZPY:    begin T <= IMP;   pc <= pc + 1; cursor <= {8'h00, azpy};     sel <= 1'b1; end

    // Абсолютный адрес
    ABS:    begin T <= ABS+1; pc <= pc + 1; cursor[ 7:0] <= i_data; end

    // Если тут JMP ABS, то обрабатывается отдельно
    ABS+1:  if (opcode == 8'h4C)
            begin T <= RST;   pc <= {i_data, cursor[7:0]}; end
    else    begin T <= IMP;   pc <= pc + 1; cursor[15:8] <= i_data; sel <= 1'b1; end

    // Абсолютный адрес +X
    ABX:    begin T <= ABX+1; pc <= pc + 1; cursor <= i_data; end
    ABX+1:  begin T <= IMP;   pc <= pc + 1; cursor <= cursor + {i_data, X}; sel <= 1'b1; end

    // Абсолютный адрес +Y
    ABY:    begin T <= ABY+1; pc <= pc + 1; cursor <= i_data; end
    ABY+1:  begin T <= IMP;   pc <= pc + 1; cursor <= cursor + {i_data, Y}; sel <= 1'b1; end

    // Косвенная адресация по X
    NDX:    begin T <= NDX+1; cursor <= azpx;    pc <= pc + 1; sel <= 1'b1; end
    NDX+1:  begin T <= NDX+2; cursor <= cursor + 1; tmpb <= i_data; end
    NDX+2:  begin T <= IMP;   cursor <= {i_data, tmpb}; end

    // Косвенная адресация по Y
    NDY:    begin T <= NDY+1; cursor <= i_data;  pc <= pc + 1; sel <= 1'b1; end
    NDY+1:  begin T <= NDY+2; cursor <= cursor8; tmpb <= i_data; end
    NDY+2:  begin T <= IMP;   cursor <= {i_data, tmpb} + Y; end

    // Относительный переход
    REL: begin

        T <= RST;
        if (condit[ opcode[7:6] ] == opcode[5])
             pc <= pc + 1'b1 + {{8{i_data[7]}}, i_data[7:0]};
        else pc <= pc + 1'b1;

    end

    // Завершение записи и выход
    WEND: begin we <= 1'b0; sel <= 1'b0; T <= RST; end

    // -----------------------------------------------------------------

    // Исполнение инструкции
    default:
    begin

        // Специальный случай (требуется PC+1)
        if (T == IMM) pc <= pc + 1'b1;

        T   <= RST;
        sel <= 1'b0;

        casex (opcode)

            // ST(A|X|Y)
            8'b100_xxx_01: begin T <= WEND; we <= 1'b1; sel <= 1'b1; o_data <= src_mux; end

            // ASL, LSR, ROL, ROR Imm
            8'b0xx_xxx_10: begin T <= WEND; we <= 1'b1; sel <= 1'b1; o_data <= alu_r; P <= alu_r;  end

            // Стандартное АЛУ. Запись в Acc, если не CMP
            8'bxxx_xxx_01: begin P <= alu_p; if (opcode[7:5] != 3'b110) A <= alu_r; end

            // LDX, LDY
            8'hA2, 8'hA6, 8'hAE, 8'hB6, 8'hBE: begin X <= alu_r; P <= alu_p; end
            8'hA0, 8'hA4, 8'hAC, 8'hB4, 8'hBC: begin Y <= alu_r; P <= alu_p; end

            // CPX, CPY
            8'hC0, 8'hC4, 8'hCC,
            8'hE0, 8'hE4, 8'hEC: P <= alu_p;

            // Неопознанная инструкция
            default: begin sel <= 1'b0; end

        endcase

    end

endcase

endmodule
