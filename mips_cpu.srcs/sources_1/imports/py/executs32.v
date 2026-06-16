`timescale 1ns / 1ps

module Executs32 (
    input [31:0]  Read_data_1,      // 从译码单元的Read_data_1中来
    input [31:0]  Read_data_2,      // 从译码单元的Read_data_2中来
    input [31:0]  Sign_extend,      // 从译码单元来的扩展后的立即数
    input [5:0]   Function_opcode,  // 取指单元来的r-类型指令功能码
    input [5:0]   Exe_opcode,       // 取指单元来的操作码 (Template: Exe_opcode)
    input [1:0]   ALUOp,            // 来自控制单元的运算指令控制编码
    input [4:0]   Shamt,            // 来自取指单元的instruction[10:6]，指定移位次数
    input         Sftmd,            // 来自控制单元的，表明是移位指令
    input         ALUSrc,           // 来自控制单元，表明第二个操作数是立即数
    input         I_format,         // 来自控制单元，表明是除beq, bne, LW, SW之外的I-类型指令
    input         Jrn,              // 来自控制单元，表明是JR指令
    output        Zero,             // 为1表明计算值为0 
    output reg [31:0] ALU_Result,   // 计算的数据结果
    output [31:0] Add_Result,       // 计算的地址结果        
    input [31:0]  PC_plus_4         // 来自取指单元的PC+4
);

    wire [31:0] Ainput, Binput;     // ALU的A和B端口输入
    wire [5:0]  Exe_code;           // 二级译码码
    wire [2:0]  ALU_ctl;            // ALU控制组合码
    reg  [31:0] Sinput;             // 移位控制模块输出
    reg  [31:0] ALU_output_mux;     // 算术逻辑运算结果
    wire [2:0]  Sftm;               // 移位类型选择

    // ALU输入选择
    assign Ainput = Read_data_1;
    assign Binput = (ALUSrc == 0) ? Read_data_2 : Sign_extend;

    // 二级控制逻辑：如果是I-format，取Opcode低3位扩展；否则取功能码
    assign Exe_code = (I_format == 0) ? Function_opcode : {3'b000, Exe_opcode[2:0]};

    // ALU控制信号生成（对应 add, sub, and, or, xor, nor, slt 等）
    assign ALU_ctl[0] = (Exe_code[0] | Exe_code[3]) & ALUOp[1];
    assign ALU_ctl[1] = ((!Exe_code[2]) | (!ALUOp[1]));
    assign ALU_ctl[2] = (Exe_code[1] & ALUOp[1]) | ALUOp[0];

    // 算术逻辑核心运算块
    always @* begin
        case(ALU_ctl)
            3'b000: ALU_output_mux = Ainput & Binput;               // AND, ANDI
            3'b001: ALU_output_mux = Ainput | Binput;               // OR, ORI
            3'b010: ALU_output_mux = Ainput + Binput;               // ADD, ADDI, LW, SW
            3'b011: ALU_output_mux = Ainput + Binput;               // ADDU, ADDIU
            3'b100: ALU_output_mux = Ainput ^ Binput;               // XOR, XORI
            3'b101: ALU_output_mux = ~(Ainput | Binput);            // NOR, LUI
            3'b110: ALU_output_mux = Ainput - Binput;               // SLTI, SUB, BEQ, BNE
            3'b111: ALU_output_mux = Ainput - Binput;               // SUBU, SLT, SLTU, SLTIU
            default: ALU_output_mux = 32'h00000000;
        endcase
    end

    // 移位运算块
    assign Sftm = Function_opcode[2:0];
    always @* begin
        if (Sftmd) begin
            case(Sftm)
                3'b000: Sinput = Binput << Shamt;                    // SLL
                3'b010: Sinput = Binput >> Shamt;                    // SRL
                3'b011: Sinput = $signed(Binput) >>> Shamt;          // SRA
                3'b100: Sinput = Binput << Ainput[4:0];              // SLLV
                3'b110: Sinput = Binput >> Ainput[4:0];              // SRLV
                3'b111: Sinput = $signed(Binput) >>> Ainput[4:0];    // SRAV
                default: Sinput = Binput;
            endcase
        end else begin
            Sinput = Binput;
        end
    end

    // 最终结果输出多路选择器
    always @* begin
        // 1. 处理比较指令 (SLT, SLTU, SLTI, SLTIU)
        if (((ALU_ctl == 3'b111) && (Exe_code[3] == 1'b1)) || ((ALU_ctl[2:1] == 2'b11) && (I_format == 1'b1))) begin
            if (Exe_code[0] == 1'b1) // 无符号
                ALU_Result = (Ainput < Binput) ? 32'h1 : 32'h0;
            else                     // 有符号
                ALU_Result = ($signed(Ainput) < $signed(Binput)) ? 32'h1 : 32'h0;
        end
        // 2. 处理高位加载指令 (LUI)
        else if ((ALU_ctl == 3'b101) && (I_format == 1'b1)) begin
            ALU_Result = {Binput[15:0], 16'h0000};
        end
        // 3. 处理移位指令
        else if (Sftmd) begin
            ALU_Result = Sinput;
        end
        // 4. 其他常规运算
        else begin
            ALU_Result = ALU_output_mux;
        end
    end

    // 分支地址计算：PC + 4 + (Sign_extend << 2)
    assign Add_Result = PC_plus_4 + {Sign_extend[29:0], 2'b00};
    
    // Zero信号：用于 BEQ/BNE 判断
    assign Zero = (ALU_output_mux == 32'h00000000) ? 1'b1 : 1'b0;

endmodule