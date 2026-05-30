`timescale 1ns / 1ps

module Idecode32(
    input  [31:0] Instruction,        // 来自取指模块
    input  [31:0] read_data,          // 从DATA RAM 取出的数据
    input  [31:0] ALU_result,         // 从执行单元来的运算的结果
    input  [31:0] opcplus4,           // 来自取指单元，JAL中用的 PC+4
    input         Jal,                // 来自控制单元，为1说明是JAL指令 
    input         RegDst,             // 来自控制单元，为1表明目的寄存器是rd，否则是rt
    input         RegWrite,           // 来自控制单元，为1表明该指令需要写寄存器
    input         MemtoReg,           // 来自控制单元，为1表明该指令需要从存储器写寄存器
    input         clock, reset,       // 时钟和复位
    
    output [31:0] read_data_1,        // 输出的第一操作数 (rs)
    output [31:0] read_data_2,        // 输出的第二操作数 (rt)
    output [31:0] Sign_extend         // 扩展后的32位立即数
);

    reg  [31:0] register[0:31];       // 寄存器组，共32个32位寄存器
    reg  [4:0]  write_register_address; // 要写的寄存器的号
    reg  [31:0] write_data;           // 要写进寄存器的数据
    
    wire [5:0]  opcode;               // 指令码(op)
    wire [4:0]  read_register_1_address; // rs
    wire [4:0]  read_register_2_address; // rt
    wire [4:0]  write_register_address_1;// rd (r-form)
    wire [4:0]  write_register_address_0;// rt (i-form)
    wire [15:0] Instruction_immediate_value; // immediate
    wire        sign;                 // 符号位
    
    integer i;                        // 循环变量
    
    // 1. 指令切片分解
    assign opcode = Instruction[31:26];		                
    assign read_register_1_address = Instruction[25:21];   	
    assign read_register_2_address = Instruction[20:16];         
    assign write_register_address_1 = Instruction[15:11];	
    assign write_register_address_0 = Instruction[20:16];	
    assign Instruction_immediate_value = Instruction[15:0];	
    
    // 2. 读寄存器 (增加 $0 保护拦截，确保不管发生什么，$0 读出来永远是 0)
    assign read_data_1 = (read_register_1_address == 5'b00000) ? 32'h0000_0000 : register[read_register_1_address];
    assign read_data_2 = (read_register_2_address == 5'b00000) ? 32'h0000_0000 : register[read_register_2_address];
    
    // 3. 确定目标写入寄存器号 (优化优先级逻辑)
    always @* begin                                
        if (Jal == 1'b1)
            write_register_address = 5'b11111;                      // JAL指令最高优先级，写 $31
        else if (RegDst == 1'b1)
            write_register_address = write_register_address_1;      // r-form，指定 rd
        else  
            write_register_address = write_register_address_0;      // i-form，指定 rt
    end

    // 4. 确定要写入的数据
    always @* begin            
        if (Jal == 1'b1) 
            write_data = opcplus4;           // JAL指令写入PC+4
        else if (MemtoReg == 1'b1)
            write_data = read_data;          // LW指令写入存储器读出的数据
        else
            write_data = ALU_result;         // 其他所有算术逻辑运算写回ALU结果
    end

    // 5. 寄存器写操作 (时序逻辑)
    always @(negedge clock or posedge reset) begin  // 建议与IF段PC更新保持同一时钟边沿，或者通常寄存器在下降沿写
        if (reset == 1'b1) begin             
            for (i = 0; i < 32; i = i + 1)
                register[i] <= 32'h0000_0000;       // 正规做法：全部初始化为 0
        end
        else if (RegWrite == 1'b1 && write_register_address != 5'b00000) begin
            // 重点保护：绝对不允许写入 $0
            register[write_register_address] <= write_data;
        end
    end
   
    // 6. 立即数扩展逻辑
    assign sign = Instruction_immediate_value[15];              
    assign Sign_extend = ((opcode == 6'b001100)       // andi
                       || (opcode == 6'b001101)       // ori
                       || (opcode == 6'b001110))      // xori
                       ? {16'h0000, Instruction_immediate_value[15:0]}   // 逻辑运算，0扩展
                       : {{16{sign}}, Instruction_immediate_value[15:0]}; // 算术/访存/分支，符号扩展

endmodule