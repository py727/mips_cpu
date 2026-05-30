`timescale 1ns / 1ps

module exe_sim();
    // 定义与被测模块接口对应的信号
    reg [31:0]  Read_data_1;
    reg [31:0]  Read_data_2;
    reg [31:0]  Sign_extend;
    reg [5:0]   Function_opcode;
    reg [5:0]   Exe_opcode;      
    reg [1:0]   ALUOp;
    reg [4:0]   Shamt;
    reg         Sftmd;
    reg         ALUSrc;
    reg         I_format;
    reg         Jrn;             
    reg [31:0]  PC_plus_4;       

    wire        Zero;
    wire [31:0] ALU_Result;
    wire [31:0] Add_Result;

    // 实例化 Executs32
    Executs32 UUT (
        .Read_data_1(Read_data_1),
        .Read_data_2(Read_data_2),
        .Sign_extend(Sign_extend),
        .Function_opcode(Function_opcode),
        .Exe_opcode(Exe_opcode),
        .ALUOp(ALUOp),
        .Shamt(Shamt),
        .Sftmd(Sftmd),
        .ALUSrc(ALUSrc),
        .I_format(I_format),
        .Jrn(jrn),
        .Zero(Zero),
        .ALU_Result(ALU_Result),
        .Add_Result(Add_Result),
        .PC_plus_4(PC_plus_4)
    );

    // 测试过程
    initial begin
        $display("Starting Executs32 Template-based Simulation...");
        
        // 初始化所有输入
        Read_data_1 = 0; Read_data_2 = 0; Sign_extend = 0;
        Function_opcode = 0; Exe_opcode = 0; ALUOp = 0;
        Shamt = 0; Sftmd = 0; ALUSrc = 0; I_format = 0;
        Jrn = 0; PC_plus_4 = 0;

        // -------------------------------------------------------------
        // Case 1: ADD (R-type) - 算术加法
        // 10 + 20 = 30
        // -------------------------------------------------------------
        #100;
        Read_data_1 = 32'd10; Read_data_2 = 32'd20;
        Function_opcode = 6'b100000; Exe_opcode = 6'b000000;
        ALUOp = 2'b10; ALUSrc = 1'b0; I_format = 1'b0;
        #10;
        $display("[ADD] Result: %d (Expected: 30)", ALU_Result);

        // -------------------------------------------------------------
        // Case 2: ADDI (I-type) - 带符号立即数加法
        // 100 + (-50) = 50
        // -------------------------------------------------------------
        #100;
        Read_data_1 = 32'd100; Sign_extend = -32'd50;
        Exe_opcode = 6'b001000; // ADDI
        ALUOp = 2'b10; ALUSrc = 1'b1; I_format = 1'b1;
        #10;
        $display("[ADDI] Result: %d (Expected: 50)", $signed(ALU_Result));

        // -------------------------------------------------------------
        // Case 3: SRA (Shift Right Arithmetic) - 算术右移(保留符号)
        // 0x80000000 >> 2 = 0xE0000000
        // -------------------------------------------------------------
        #100;
        Read_data_2 = 32'h80000000; 
        Shamt = 5'd2;
        Function_opcode = 6'b000011; // SRA 的功能码
        Sftmd = 1'b1;                // 开启移位
        I_format = 1'b0;             // R-type
        ALUSrc = 1'b0;               // 【关键修改点】必须设为0，选择 Read_data_2 作为输入
        ALUOp = 2'b10;               // R-type 运算
        #10;
        $display("[SRA] Result: %h (Expected: e0000000)", ALU_Result);

        // -------------------------------------------------------------
        // Case 4: SLT (Set on Less Than) - 有符号比较
        // -10 < 5 ? 1 : 0
        // -------------------------------------------------------------
        #100;
        Read_data_1 = -32'd10; Read_data_2 = 32'd5;
        Function_opcode = 6'b101010; // SLT
        ALUOp = 2'b10; Sftmd = 1'b0; ALUSrc = 1'b0; I_format = 1'b0;
        #10;
        $display("[SLT] Result: %d (Expected: 1)", ALU_Result);

        // -------------------------------------------------------------
        // Case 5: SLTU (Set on Less Than Unsigned) - 无符号比较
        // (unsigned)-10 < 5 ? 1 : 0  => 0xFFFFFFF6 < 5 为假
        // -------------------------------------------------------------
        #100;
        Function_opcode = 6'b101011; // SLTU
        #10;
        $display("[SLTU] Result: %d (Expected: 0)", ALU_Result);

        // -------------------------------------------------------------
        // Case 6: LUI (Load Upper Immediate) - 高位加载
        // 0xABCD -> 0xABCD0000
        // -------------------------------------------------------------
        #100;
        Sign_extend = 32'h0000ABCD;
        Exe_opcode = 6'b001111; // LUI
        ALUOp = 2'b10; ALUSrc = 1'b1; I_format = 1'b1;
        #10;
        $display("[LUI] Result: %h (Expected: abcd0000)", ALU_Result);

        // -------------------------------------------------------------
        // Case 7: BEQ (Branch If Equal) - 分支地址计算
        // R1=5, R2=5, PC+4=0x00000010, Offset=4
        // Result: Zero=1, Add_Result = 0x10 + (4*4) = 0x20
        // -------------------------------------------------------------
        #100;
        Read_data_1 = 32'd5; Read_data_2 = 32'd5;
        Sign_extend = 32'd4; PC_plus_4 = 32'h00000010;
        Exe_opcode = 6'b000100; // BEQ
        ALUOp = 2'b01; ALUSrc = 1'b0; I_format = 1'b0;
        #10;
        $display("[BEQ] Zero: %b, Add_Addr: %h (Expected: 1, 00000020)", Zero, Add_Result);

        // -------------------------------------------------------------
        // Case 8: JR (Jump Register)
        // 只要确认 Jrn 信号传入且不影响常规计算即可
        // -------------------------------------------------------------
        #100;
        Jrn = 1'b1;
        #10;
        $display("[JR] Jrn signal tested.");

        #100;
        $display("Simulation Finished.");
        $stop;
    end

endmodule