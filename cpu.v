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
        8'b0xx_010_10: T <= ACC;
        default:       T <= IMP;
        endcase

        pc     <= pc + 1'b1;
        opcode <= i_data;

    end

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

    // Переход относительный
    REL:    begin end

    // Исполнение инструкции
    IMM, IMP, ACC: begin

        if (T == IMM) pc <= pc + 1'b1;

    end

endcase

endmodule
