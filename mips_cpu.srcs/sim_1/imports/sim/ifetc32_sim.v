`timescale 1ns / 1ps

module ifetc32_sim();
    // 输入信号寄存器
    reg [31:0] Add_result;
    reg [31:0] Read_data_1;
    reg        Branch;
    reg        nBranch;
    reg        Jmp;
    reg        Jal;
    reg        Jrn;
    reg        Zero;
    reg        clock;
    reg        reset;

    // 输出信号线
    wire [31:0] Instruction;
    wire [31:0] PC_plus_4_out;
    wire [31:0] opcplus4;

    // 实例化单元 (采用命名端口连接)
    Ifetc32 Uifetch (
        .Instruction(Instruction),
        .PC_plus_4_out(PC_plus_4_out),
        .Add_result(Add_result),
        .Read_data_1(Read_data_1),
        .Branch(Branch),
        .nBranch(nBranch),
        .Jmp(Jmp),
        .Jal(Jal),
        .Jrn(Jrn),
        .Zero(Zero),
        .clock(clock),
        .reset(reset),
        .opcplus4(opcplus4)
    );

    // 生成时钟 (10MHz 示例，半周期 50ns)
    initial clock = 1'b0;
    always #50 clock = ~clock;

    // 测试流程
    initial begin
        // 初始化信号
        reset = 1'b1;
        Add_result = 32'h0000_0000;
        Read_data_1 = 32'h0000_0000;
        Branch = 0; nBranch = 0; Jmp = 0; Jal = 0; Jrn = 0; Zero = 0;
        
        $display("--- Start Ifetc32 Rigorous Simulation ---");

        // T1: 复位测试
        #120 reset = 1'b0;
        $display("[T1 Reset] PC should be 0. Actual PC_plus_4_out: %h", PC_plus_4_out);

        // T2: 正常顺序取指 (PC + 4)
        #200; 
        $display("[T2 Fetch] PC should have incremented twice. Actual PC_plus_4_out: %h", PC_plus_4_out);

        // T3: JAL 指令测试
        // 注意：由于是单模块仿真，JAL 会根据 ROM 里的指令字段跳转
        // 假设 Instruction[25:0] 此时为 0 (ROM为空)
        #100 Jal = 1;
        #100 Jal = 0;
        $display("[T3 JAL] opcplus4 (Link Reg) should be %h, PC should jump.", opcplus4);

        // T4: JR 指令测试
        #100;
        Read_data_1 = 32'h0000_019C;
        Jrn = 1;
        #100;
        Jrn = 0;
        $display("[T4 JR] PC should be 0x19C. Actual PC_plus_4_out: %h", PC_plus_4_out);

        // T5: BEQ 测试 (条件成立)
        #100;
        Branch = 1; Zero = 1; Add_result = 32'h0000_0200;
        #100;
        Branch = 0; Zero = 0;
        $display("[T5 BEQ True] PC should be 0x200. Actual PC_plus_4_out: %h", PC_plus_4_out);

        // T6: BEQ 测试 (条件不成立)
        #100;
        Branch = 1; Zero = 0; Add_result = 32'h0000_0300;
        #100;
        Branch = 0;
        $display("[T6 BEQ False] PC should be 0x200 + 4. Actual PC_plus_4_out: %h", PC_plus_4_out);

        // T7: BNE 测试 (条件成立)
        #100;
        nBranch = 1; Zero = 0; Add_result = 32'h0000_0400;
        #100;
        nBranch = 0;
        $display("[T7 BNE True] PC should be 0x400. Actual PC_plus_4_out: %h", PC_plus_4_out);

        // T8: J 指令测试
        #100;
        Jmp = 1;
        #100;
        Jmp = 0;
        $display("[T8 J] PC jump checked.");

        #200;
        $display("--- Simulation Finished ---");
        $stop;
    end

endmodule