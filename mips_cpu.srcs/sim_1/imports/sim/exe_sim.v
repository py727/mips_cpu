`timescale 1ns / 1ps

module exe_sim();
    // 1. 定义与被测模块接口对应的信号
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

    // 2. 实例化 Executs32
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
        .Jrn(Jrn),               
        .Zero(Zero),
        .ALU_Result(ALU_Result),
        .Add_Result(Add_Result),
        .PC_plus_4(PC_plus_4)
    );

    // 3. 定义自动化测试任务 (Task)
    // 该任务自动施加激励、等待延时、并进行结果比对
    task verify_case(
        input [31:0] r1, r2, ext, pc4,
        input [5:0]  func, exe_op,
        input [1:0]  alu_op,
        input [4:0]  sh,
        input        sft, src, i_fmt, jr,
        input [31:0] exp_res, exp_add,
        input        exp_zero,
        input [127:0] case_name // 用于打印通道名称
    );
        begin
            // 施加激励
            Read_data_1 = r1; Read_data_2 = r2; Sign_extend = ext; PC_plus_4 = pc4;
            Function_opcode = func; Exe_opcode = exe_op; ALUOp = alu_op;
            Shamt = sh; Sftmd = sft; ALUSrc = src; I_format = i_fmt; Jrn = jr;
            
            #10; // 给足组合逻辑物理延迟时间（模拟建立稳定状态）
            
            // 自动化断言比对
            if ((ALU_Result === exp_res) && (Add_Result === exp_add) && (Zero === exp_zero)) begin
                $display("[PASS] %0s | ALU_Result=%h, Add_Result=%h, Zero=%b", 
                         case_name, ALU_Result, Add_Result, Zero);
            end else begin
                $display("[FAIL] %0s | ERROR!", case_name);
                $display("       Expected: ALU_Result=%h, Add_Result=%h, Zero=%b", exp_res, exp_add, exp_zero);
                $display("       Got     : ALU_Result=%h, Add_Result=%h, Zero=%b", ALU_Result, Add_Result, Zero);
            end
        end
    endtask

    // 4. 测试过程
    initial begin
        $display("Starting Executs32 Professional Self-Checking Simulation...");
        
        // ---------------------------------------------------------------------------------------------------------------------------------
        // 任务参数顺序：r1, r2, ext, pc4, func, exe_op, alu_op, sh, sft, src, i_fmt, jr, exp_res, exp_add, exp_zero, case_name
        // ---------------------------------------------------------------------------------------------------------------------------------
        
        // Case 1: ADD (R-type)
        verify_case(32'd10, 32'd20, 32'd0, 32'd0, 6'b100000, 6'b000000, 2'b10, 5'd0, 0, 0, 0, 0, 32'd30, 32'd0, 1'b0, "Case 1: ADD");

        // Case 2: ADDI (I-type, 带符号加法)
        // 100 + (-50) = 50. 同时分支计算：0 + (-50 << 2) = -200 (32'hffffff38)
        verify_case(32'd100, 32'd0, -32'd50, 32'd0, 6'b000000, 6'b001000, 2'b10, 5'd0, 0, 1, 1, 0, 32'd50, 32'hffffff38, 1'b0, "Case 2: ADDI");

        // Case 3: SRA (算术右移，符号位保持)
        verify_case(32'd0, 32'h80000000, 32'd0, 32'd0, 6'b000011, 6'b000000, 2'b10, 5'd2, 1, 0, 0, 0, 32'he0000000, 32'd0, 1'b0, "Case 3: SRA");

        // Case 4: SLT (有符号比较) -10 < 5 成立
        verify_case(-32'd10, 32'd5, 32'd0, 32'd0, 6'b101010, 6'b000000, 2'b10, 5'd0, 0, 0, 0, 0, 32'd1, 32'd0, 1'b0, "Case 4: SLT");

        // Case 5: SLTU (无符号比较) 无符号下 -10(0xfffffff6) > 5，不成立
        verify_case(-32'd10, 32'd5, 32'd0, 32'd0, 6'b101011, 6'b000000, 2'b10, 5'd0, 0, 0, 0, 0, 32'd0, 32'd0, 1'b0, "Case 5: SLTU");

        // Case 6: LUI (加载高位立即数) 
        // 扩展立即数高位拼接 16'b0。同时算地址分支：0xABCD << 2 = 0x2AF34
        verify_case(32'd0, 32'd0, 32'h0000ABCD, 32'd0, 6'b000000, 6'b001111, 2'b10, 5'd0, 0, 1, 1, 0, 32'habcd0000, 32'h0002AF34, 1'b0, "Case 6: LUI");

        // Case 7: BEQ (相等分支跳转计算)
        // 5 - 5 = 0 (Zero=1), 分支目标地址：0x10 + (4<<2) = 0x20
        verify_case(32'd5, 32'd5, 32'd4, 32'h00000010, 6'b000000, 6'b000100, 2'b01, 5'd0, 0, 0, 0, 0, 32'd0, 32'h00000020, 1'b1, "Case 7: BEQ");

        // Case 8: JR (寄存器跳转信号测试)
        verify_case(32'd0, 32'd0, 32'd0, 32'd0, 6'b000000, 6'b000000, 2'b00, 5'd0, 0, 0, 0, 1, 32'd0, 32'd0, 1'b1, "Case 8: JR");

        // Case 9: NOR (R-type, 或非逻辑)
        // ~(0x0000FFFF | 0xFFFF0000) = 32'h00000000
        verify_case(32'h0000FFFF, 32'hFFFF0000, 32'd0, 32'd0, 6'b100111, 6'b000000, 2'b10, 5'd0, 0, 0, 0, 0, 32'h00000000, 32'd0, 1'b1, "Case 9: NOR");

        // Case 10: ANDI (I-type, 立即数逻辑与)
        // 0xFFFFFFFF & 0x0000FF00 (零扩展) = 0x0000FF00
        verify_case(32'hFFFFFFFF, 32'd0, 32'h0000FF00, 32'd0, 6'b000000, 6'b001100, 2'b10, 5'd0, 0, 1, 1, 0, 32'h0000FF00, 32'd0, 1'b0, "Case 10: ANDI");

        // Case 11: SRAV (R-type, 变量算术右移)
        // -268435456 (32'hf0000000) >>> 移位寄存器低5位 36%32=4 -> 32'hff000000
        verify_case(32'h00000024, 32'hf0000000, 32'd0, 32'd0, 6'b000111, 6'b000000, 2'b10, 5'd0, 1, 0, 0, 0, 32'hff000000, 32'd0, 1'b0, "Case 11: SRAV");

        // Case 12: SLTI (I-type, 有符号立即数比较)
        // -10 < 5 成立 -> 1。同时分支计算：0 + (5<<2) = 20 (32'd20)
        verify_case(-32'd10, 32'd0, 32'd5, 32'd0, 6'b000000, 6'b001010, 2'b10, 5'd0, 0, 1, 1, 0, 32'd1, 32'd20, 1'b0, "Case 12: SLTI");

        // Case 13: SUBU (R-type, 无符号寄存器减法)
        // 50 - 20 = 30
        verify_case(32'd50, 32'd20, 32'd0, 32'd0, 6'b100011, 6'b000000, 2'b10, 5'd0, 0, 0, 0, 0, 32'd30, 32'd0, 1'b0, "Case 13: SUBU");

        // Case 14: LW/SW 地址计算通路
        // 寄存器 A(100) + 偏移量(4) = 104。
        verify_case(32'd100, 32'd0, 32'd4, 32'd0, 6'b000000, 6'b100011, 2'b00, 5'd0, 0, 1, 0, 0, 32'd104, 32'd16, 1'b0, "Case 14: LW Address");

        $display("All test cases completed.");
        $stop;
    end

endmodule
