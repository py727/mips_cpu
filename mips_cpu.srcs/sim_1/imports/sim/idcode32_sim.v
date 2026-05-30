`timescale 1ns / 1ps

module idcode32_sim();
    // 1. 定义输入输出信号
    reg [31:0]  Instruction;
    reg [31:0]  read_data;     // 模拟从 Data RAM 取出的数据
    reg [31:0]  ALU_result;    // 模拟从 ALU 计算出的结果
    reg [31:0]  opcplus4;      // 模拟 JAL 指令所需的 PC+4
    reg         Jal; 
    reg         RegWrite;
    reg         MemtoReg;
    reg         RegDst;
    reg         clock;
    reg         reset;

    wire [31:0] read_data_1;   // rs 读出数据
    wire [31:0] read_data_2;   // rt 读出数据
    wire [31:0] Sign_extend;   // 立即数扩展结果

    // 2. 实例化被测模块
    Idecode32 Uid (
        .Instruction(Instruction),
        .read_data(read_data),
        .ALU_result(ALU_result),
        .opcplus4(opcplus4),
        .Jal(Jal),
        .RegWrite(RegWrite),
        .MemtoReg(MemtoReg),
        .RegDst(RegDst),
        .clock(clock),
        .reset(reset),
        .read_data_1(read_data_1),
        .read_data_2(read_data_2),
        .Sign_extend(Sign_extend)
    );

    // 3. 时钟生成 (周期 100ns)
    initial clock = 1'b0;
    always #50 clock = ~clock;            

    // 4. 测试流程
    initial begin
        // 初始化信号
        Instruction = 32'h0000_0000;
        read_data = 32'h0000_0000;
        ALU_result = 32'h0000_0000;
        opcplus4 = 32'h0000_0000;
        Jal = 0; RegWrite = 0; MemtoReg = 0; RegDst = 0;
        
        $display("=========================================================");
        $display("           Start Idecode32 Rigorous Simulation           ");
        $display("=========================================================");

        // -------------------------------------------------------------
        // T0: 复位测试
        // -------------------------------------------------------------
        reset = 1'b1;
        #120; // 越过第一个时钟边沿
        reset = 1'b0;
        $display("[T0 Reset] Registers cleared.");

        // -------------------------------------------------------------
        // T1: R型指令写入验证 (ADD)
        // 目标：将 0x000000AA 写入 rd($7)
        // -------------------------------------------------------------
        @(posedge clock); 
        // add $7, $2, $3 -> rs=2, rt=3, rd=7
        Instruction = {6'b000000, 5'd2, 5'd3, 5'd7, 5'd0, 6'b100000}; 
        ALU_result  = 32'h000000AA;
        RegWrite = 1; RegDst = 1; MemtoReg = 0; Jal = 0;
        
        // 等待一个时钟周期（让下降沿完成写入），然后读出验证
        @(posedge clock);
        Instruction = {6'b000000, 5'd7, 5'd0, 5'd0, 5'd0, 6'b000000}; // rs=7，将其读出到 read_data_1
        RegWrite = 0; // 停止写入
        #10; // 等待组合逻辑生效
        $display("[T1 R-Type] Write $7. Read out: %h (Expected: 000000aa)", read_data_1);

        // -------------------------------------------------------------
        // T2: I型指令写入验证 (ADDI) + 符号扩展验证
        // 目标：将 0x000000BB 写入 rt($3)；立即数 0x8037 应该符号扩展为 0xFFFF8037
        // -------------------------------------------------------------
        @(posedge clock);
        // addi $3, $7, 0x8037 -> rs=7, rt=3, imm=0x8037
        Instruction = {6'b001000, 5'd7, 5'd3, 16'h8037}; 
        ALU_result  = 32'h000000BB;
        RegWrite = 1; RegDst = 0; MemtoReg = 0; Jal = 0;

        #10; // 给组合逻辑 10ns 的时间进行计算
        // 【修改点】：在组合逻辑计算完毕，且 Instruction 还未被替换时，立刻检查扩展结果
        $display("[T2 SignEx] Immediate 0x8037. Extended: %h (Expected: ffff8037)", Sign_extend);

        // 然后再等下一个时钟上升沿，去检查“时序逻辑（寄存器写操作）”是否成功
        @(posedge clock);
        Instruction = {6'b000000, 5'd3, 5'd0, 5'd0, 5'd0, 6'b000000}; // rs=3，将其读出
        RegWrite = 0;
        #10;
        $display("[T2 I-Type] Write $3. Read out: %h (Expected: 000000bb)", read_data_1);

        // -------------------------------------------------------------
        // T3: 逻辑运算零扩展验证 (ANDI)
        // 目标：立即数 0x8097 应该零扩展为 0x00008097
        // -------------------------------------------------------------
        @(posedge clock);
        // andi $4, $2, 0x8097 -> rs=2, rt=4, imm=0x8097
        Instruction = {6'b001100, 5'd2, 5'd4, 16'h8097}; 
        RegWrite = 0; // 此处只测扩展，不测写
        #10;
        $display("[T3 ZeroEx] Immediate 0x8097. Extended: %h (Expected: 00008097)", Sign_extend);

        // -------------------------------------------------------------
        // T4: LW 访存指令写入验证
        // 目标：通过 MemtoReg=1，将 read_data (0x000000CC) 写入 rt($6)
        // -------------------------------------------------------------
        @(posedge clock);
        // lw $6, 0($0) -> rs=0, rt=6
        Instruction = {6'b100011, 5'd0, 5'd6, 16'h0000};
        read_data   = 32'h000000CC;
        RegWrite = 1; RegDst = 0; MemtoReg = 1; Jal = 0;

        @(posedge clock);
        Instruction = {6'b000000, 5'd6, 5'd0, 5'd0, 5'd0, 6'b000000}; // rs=6
        RegWrite = 0;
        #10;
        $display("[T4 Mem2Reg] Write $6. Read out: %h (Expected: 000000cc)", read_data_1);

        // -------------------------------------------------------------
        // T5: JAL 指令写入 $31 验证
        // 目标：将 PC+4 (0x00000018) 写入 $31 (即使 RegDst=0/X，也必须写入$31)
        // -------------------------------------------------------------
        @(posedge clock);
        // jal 0x000000
        Instruction = {6'b000011, 26'h0000000};
        opcplus4    = 32'h00000018;
        RegWrite = 1; RegDst = 0; MemtoReg = 0; Jal = 1; 

        @(posedge clock);
        Instruction = {6'b000000, 5'd31, 5'd0, 5'd0, 5'd0, 6'b000000}; // rs=31
        RegWrite = 0; Jal = 0;
        #10;
        $display("[T5 JAL $31] Write $31. Read out: %h (Expected: 00000018)", read_data_1);

        // -------------------------------------------------------------
        // T6: $0 寄存器保护机制验证
        // 目标：试图向 $0 写入 0xDEADBEEF，验证其是否依然保持为 0
        // -------------------------------------------------------------
        @(posedge clock);
        // add $0, $1, $2 -> rs=1, rt=2, rd=0
        Instruction = {6'b000000, 5'd1, 5'd2, 5'd0, 5'd0, 6'b100000}; 
        ALU_result  = 32'hDEADBEEF;
        RegWrite = 1; RegDst = 1; MemtoReg = 0; Jal = 0;

        @(posedge clock);
        Instruction = {6'b000000, 5'd0, 5'd0, 5'd0, 5'd0, 6'b000000}; // rs=0
        RegWrite = 0;
        #10;
        $display("[T6 $0 Prot] Attempted write 0xDEADBEEF. Read out $0: %h (Expected: 00000000)", read_data_1);

        $display("=========================================================");
        $display("                  Simulation Finished                    ");
        $display("=========================================================");
        $stop;
    end 
           
endmodule