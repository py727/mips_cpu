`timescale 1ns / 1ps

module Ifetc32(
    input  [31:0] Add_result,      // 来自执行单元，算出的分支跳转地址
    input  [31:0] Read_data_1,     // 来自译码单元，jr指令用的寄存器地址
    input         Branch,          // 来自控制单元，为1表明是Beq指令
    input         nBranch,         // 来自控制单元，为1表明是Bne指令
    input         Jmp,             // 来自控制单元，为1表明是J指令
    input         Jal,             // 来自控制单元，为1表明是Jal指令
    input         Jrn,             // 来自控制单元，为1表明当前指令是jr
    input         Zero,            // 来自执行单元，为1表明计算值为0
    input         clock,           // 时钟
    input         reset,           // 复位(高电平有效)
    
    output [31:0] Instruction,     // 输出指令到其他模块
    output [31:0] PC_plus_4_out,   // 送往执行单元的 PC+4
    output [31:0] opcplus4         // JAL指令专用的PC+4
);

    wire [31:0] PC_plus_4;         // 内部使用 PC+4
    reg  [31:0] PC;                // 当前指令的PC寄存器
    reg  [31:0] next_PC;           // 下条指令的PC地址（组合逻辑中间变量）

    // 1. 程序存储器 ROM 实例化
    prgrom instmem(
        .clka(clock),              // IP核内部自带寄存器/触发逻辑
        .addra(PC[15:2]),          // 输入地址
        .douta(Instruction)        // 输出指令
    );   

    // 2. 计算顺序下一跳 PC+4
    // 巧妙利用位拼接，硬件上只需对 31:2 位做加法，节省资源
    assign PC_plus_4[31:2] = PC[31:2] + 1'b1;  
    assign PC_plus_4[1:0]  = 2'b00;

    // 3. 组合逻辑输出赋值
    assign PC_plus_4_out = PC_plus_4;
    
    // 修复JAL写回的组合逻辑延迟Bug
    // 单周期CPU中，写回数据必须作为组合逻辑立即可用
    assign opcplus4 = PC_plus_4;

    // 4. 统一的 Next PC 选择器 (组合逻辑 MUX)
    always @* begin
        if (((Branch == 1'b1) && (Zero == 1'b1)) || ((nBranch == 1'b1) && (Zero == 1'b0))) begin
            next_PC = Add_result;                          // beq 或 bne 指令触发跳转
        end 
        else if (Jrn == 1'b1) begin
            next_PC = Read_data_1;                         // jr 指令，直接跳向寄存器所存地址
        end 
        else if (Jmp == 1'b1 || Jal == 1'b1) begin
            // J 和 JAL 的寻址方式：PC+4的高4位 拼接 指令的[25:0] 并在最低位补2个0（即乘以4）
            next_PC = {PC_plus_4[31:28], Instruction[25:0], 2'b00};
        end 
        else begin
            next_PC = PC_plus_4;                           // 默认情况：顺序执行
        end
    end
    
    // 5. PC 寄存器状态更新 (时序逻辑)
    // 引入异步复位，使得测试和初始化更加准确
    always @(negedge clock or posedge reset) begin  
         if (reset == 1'b1) begin
             PC <= 32'h0000_0000;
         end else begin
             PC <= next_PC; // 无论什么跳转，这里只负责单纯的寄存器更新
         end
    end

endmodule