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

        // T1: 复位测试 - 保持复位2个周期后释放
        repeat(2) @(negedge clock);
        reset <= 1'b0;
        @(negedge clock);  // 复位释放后的第一条指令取指 (PC: 0→4)
        #1;  // 等待 NBA 更新完成
        $display("[T1 Reset] PC+4=%h (PC=4, first post-reset fetch)", PC_plus_4_out);

        // T2: 正常顺序取指 (再取2条指令)
        repeat(2) @(negedge clock);  // PC: 4→8→C
        #1;
        $display("[T2 Fetch] PC+4=%h (PC=0xC, 3 total fetches)", PC_plus_4_out);

        // T3: JAL 指令测试
        // 注意: ROM 中有真实指令, JAL 目标地址由 Instruction[25:0] 决定
        Jal = 1;
        @(negedge clock);  // JAL 触发，PC 跳转到 JAL 目标
        Jal = 0;
        #1;
        $display("[T3 JAL] PC+4=%h (jumped to JAL target, opcplus4=%h)", 
                 PC_plus_4_out, opcplus4);

        // T4: JR 指令测试
        Read_data_1 = 32'h0000_019C;
        Jrn = 1;
        @(negedge clock);  // JR 触发，PC 跳转到 Read_data_1
        Jrn = 0;
        #1;
        $display("[T4 JR] PC+4=%h (PC should be 0x19C after JR)", PC_plus_4_out);

        // T5: BEQ 测试 (条件成立)
        Branch = 1; Zero = 1; Add_result = 32'h0000_0200;
        @(negedge clock);  // BEQ 条件成立，PC 跳转到 Add_result
        Branch = 0; Zero = 0;
        #1;
        $display("[T5 BEQ True] PC+4=%h (PC should be 0x200 after BEQ taken)", PC_plus_4_out);

        // T6: BEQ 测试 (条件不成立)
        Branch = 1; Zero = 0; Add_result = 32'h0000_0300;
        @(negedge clock);  // BEQ 条件不成立，PC 顺序递增
        Branch = 0;
        #1;
        $display("[T6 BEQ False] PC+4=%h (PC should be 0x204, BEQ not taken)", PC_plus_4_out);

        // T7: BNE 测试 (条件成立)
        nBranch = 1; Zero = 0; Add_result = 32'h0000_0400;
        @(negedge clock);  // BNE 条件成立，PC 跳转到 Add_result
        nBranch = 0;
        #1;
        $display("[T7 BNE True] PC+4=%h (PC should be 0x400 after BNE taken)", PC_plus_4_out);

        // T8: J 指令测试
        Jmp = 1;
        @(negedge clock);  // J 触发，PC 跳转到 J 目标
        Jmp = 0;
        #1;
        $display("[T8 J] PC+4=%h (jumped to J target)", PC_plus_4_out);

        repeat(2) @(negedge clock);
        $display("--- Simulation Finished ---");
        $finish;
    end

endmodule
