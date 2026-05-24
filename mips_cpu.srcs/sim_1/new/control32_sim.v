`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/05/23 10:56:19
// Design Name: 
// Module Name: control32_sim
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module control32_sim(
    );
       reg[5:0]   Opcode = 6'b000000;            // 来自取指单元instruction[31..26]
       reg[5:0]   Function_opcode = 6'b100000;      // add
       wire       Jrn;              // 1表明当前指令是jr
       wire       RegDST;          // 1表明目的寄存器是rd，否则目的寄存器是rt
       wire       ALUSrc;          // 1表明第二个操作数是立即数，进行有符号扩展（beq，bne除外）
       wire       MemtoReg;     // 1表明要从存储器或I/O读数据到寄存器
       wire       RegWrite;         //  1表明该指令需要写寄存器
       wire       MemWrite;       //  1表明该指令需要写存储器
       wire       Branch;        //  1表明是Beq指令
       wire       nBranch;       //  1表明是Bne指令
       wire       Jmp;            //  1表明是J指令
       wire       Jal;            //  1表明是Jal指令
       wire       I_format;      //  1表明该指令是除beq，bne，LW，SW之外的其他I-类型指令
       wire       Sftmd;         //  1表明是移位指令
       wire[1:0]  ALUOp;
    
        control32 Uctrl(Opcode,Function_opcode,Jrn,RegDST,ALUSrc,MemtoReg,RegWrite,MemWrite,Branch,nBranch,Jmp,Jal,I_format,Sftmd,ALUOp);
        
        initial begin
        #200 Function_opcode = 6'b001000;  //jr
        #200 Opcode = 6'b001000;  //addi
        #200 Opcode = 6'b100011;  //lw
        #200 Opcode = 6'b101011;  //sw
        #200 Opcode = 6'b000100;  //beq
        #200 Opcode = 6'b000101;  //bne
        #200 Opcode = 6'b000010;  //j
        #200 Opcode = 6'b000011;  //jal
        #250 begin Opcode =  6'b000000;Function_opcode = 6'b000010;end;  //srl
        end
endmodule
