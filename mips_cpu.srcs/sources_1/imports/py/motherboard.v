`timescale 1ns / 1ps

module motherboard(rst, clk, d);
    input rst;               // 板上的Reset信号，高电平复位
    input clk;               // 板上的100MHz时钟信号
    output d;                // 这里的 d 通常可以接一个 LED 或者作为调试输出
    
    // ================= 时钟与取指阶段 (Instruction Fetch) =================
    wire clock;              // 分频后的CPU全局工作时钟，驱动PC更新和存储器访问
    wire[31:0] instruction;  // 从程序存储器(ROM)取出的32位指令码
    wire[31:0] pc_plus_4;    // 当前PC地址 + 4，用于顺序执行
    wire[31:0] opcplus4;     // 特指JAL指令执行时需要存入$31寄存器的返回地址(PC+4)

    // ================= 译码与寄存器堆 (Decode & Register File) =================
    wire[31:0] read_data_1;  // 寄存器堆端口1读出的数据 (rs寄存器内容)
    wire[31:0] read_data_2;  // 寄存器堆端口2读出的数据 (rt寄存器内容)
    wire[31:0] sign_extend;  // 16位立即数经过符号扩展或零扩展后的32位数据

    // ================= 执行与运算阶段 (Execute/ALU) =================
    wire[31:0] alu_result;   // ALU运算后的数据结果，或作为访问内存的物理地址
    wire[31:0] add_result;   // 分支跳转的目标地址计算结果 (PC+4 + offset*4)
    wire zero;               // ALU状态标志，计算结果为0时置1，用于BEQ/BNE判断

    // ================= 访存与写回阶段 (Memory & Write Back) =================
    wire[31:0] read_data;    // 从数据存储器(RAM)中读出的32位数据
    wire[31:0] write_data;   // 最终选择的写回寄存器堆的数据通路

    // ================= 控制单元信号 (Control Unit Signals) =================
    // --- 寄存器控制 ---
    wire regdst;             // 1: 写回rd(R型); 0: 写回rt(I型)
    wire regwrite;           // 寄存器堆写使能信号，为1时允许数据写入寄存器

    // --- ALU控制 ---
    wire alusrc;             // 1: ALU源B来自立即数; 0: ALU源B来自寄存器rt
    wire[1:0] aluop;         // ALU操作码类别，配合Funct字段决定具体运算
    wire sftmd;              // 移位指令标志，为1时选择移位器输出

    // --- 访存控制 ---
    wire memwrite;           // 存储器写使能，为1时执行SW指令
    wire memtoreg;           // 1: 写回数据来自内存(LW); 0: 写回数据来自ALU

    // --- 指令格式与类型控制 ---
    wire i_format;           // 标识除访存和分支外的I型指令(如addi, andi等)
    wire branch;             // BEQ指令标志
    wire nbranch;            // BNE指令标志
    wire jmp;                // J型跳转指令标志
    wire jal;                // JAL指令标志
    wire jrn;                // JR指令标志
    
    // 时钟分频
    cpuclk cpuclk(
        .clk_in1(clk),    
        .clk_out1(clock)  
    );

    // 取指单元
    Ifetc32 ifetch(
        .Instruction(instruction),
        .PC_plus_4_out(pc_plus_4),
        .Add_result(add_result),
        .Branch(branch),
        .nBranch(nbranch),
        .Jmp(jmp),
        .Jal(jal),
        .Jrn(jrn),
        .Read_data_1(read_data_1),
        .Zero(zero),
        .clock(clock),  
        .reset(rst),
        .opcplus4(opcplus4)
    );
    
    // 译码单元
    Idecode32 idecode(
        .read_data_1(read_data_1),
        .read_data_2(read_data_2),
        .Instruction(instruction),
        .read_data(read_data),
        .ALU_result(alu_result),
        .MemtoReg(memtoreg),
        .RegWrite(regwrite),
        .RegDst(regdst),
        .Sign_extend(sign_extend),
        .Jal(jal),
        .clock(clock),    
        .reset(rst),
        .opcplus4(opcplus4)
    );
    
    // 控制单元
    control32 control(
        .Opcode(instruction[31:26]),
        .Function_opcode(instruction[5:0]),
        .RegDST(regdst),
        .ALUSrc(alusrc),
        .MemtoReg(memtoreg),
        .RegWrite(regwrite),
        .MemWrite(memwrite),
        .ALUOp(aluop),
        .I_format(i_format),
        .Branch(branch),
        .nBranch(nbranch),
        .Sftmd(sftmd),
        .Jal(jal),
        .Jrn(jrn),
        .Jmp(jmp)
    );
                      
    // 执行单元
    Executs32 execute(
        .Read_data_1(read_data_1),
        .Read_data_2(read_data_2),
        .Sign_extend(sign_extend),
        .Function_opcode(instruction[5:0]),
        .Exe_opcode(instruction[31:26]), // 修改了端口名以匹配模板
        .Shamt(instruction[10:6]),
        .Sftmd(sftmd),
        .ALUOp(aluop),
        .ALUSrc(alusrc),
        .I_format(i_format),             // 端口位置已按模板微调
        .Jrn(jrn),                       // 增加了模板要求的Jrn端口
        .Zero(zero),
        .ALU_Result(alu_result),
        .Add_Result(add_result),
        .PC_plus_4(pc_plus_4)
     );
    
    // 数据存储器单元
    dmemory32 memory(
        .read_data(read_data),
        .address(alu_result),
        .write_data(read_data_2),
        .Memwrite(memwrite),
        .clock(clock)    
    );
    
    assign d = 1'b1;

endmodule