`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module control32(Opcode,Function_opcode,Jrn,RegDST,ALUSrc,MemtoReg,RegWrite,MemWrite,Branch,nBranch,Jmp,Jal,I_format,Sftmd,ALUOp);
    input[5:0]   Opcode;            // 来自取指单元instruction[31:26]
    input[5:0]   Function_opcode;  	// 来自取指单元R型指令 instructions[5:0]
    output       Jrn;         	  // 为1表明当前指令是jr
    output       RegDST;          // 为1表明目的寄存器是rd，否则目的寄存器是rt
    output       ALUSrc;          // 为1表明第二个操作数是立即数，进行有符号扩展（beq、bne除外）
    output       MemtoReg;     // 为1表明需要从存储器或I/O读数据到寄存器
    output       RegWrite;   	  //  为1表明该指令需要写寄存器
    output       MemWrite;       //  为1表明该指令需要写存储器
    output       Branch;        //  为1表明是Beq指令
    output       nBranch;       //  为1表明是Bne指令
    output       Jmp;            //  为1表明是J指令
    output       Jal;            //  为1表明是Jal指令
    output       I_format;      //  为1表明该指令是除beq、bne、LW、SW之外的其他I-类型指令
    output       Sftmd;         //  为1表明是移位指令
    output[1:0]  ALUOp;       //  是R型指令或I_format=1时位1为1, 是beq、bne指令则位0为1

    wire R_format,Lw,Sw;        // 为1表示是R-类型指令/lw指令/sw指令
 
    assign R_format = ((Opcode==6'b000000)&&(Function_opcode!=6'b001000)) ? 1'b1 : 1'b0;    	//根据op判断是否为R型指令（除jr）
    assign RegDST = R_format;                               //R型指令（除jr）需要RegDst信号选择目标寄存器为rd
    assign Sftmd = (((Function_opcode==6'b000000)||(Function_opcode==6'b000010)||(Function_opcode==6'b000011)
                               ||(Function_opcode==6'b000100)||(Function_opcode==6'b000110)||(Function_opcode==6'b000111))
                                && R_format)? 1'b1:1'b0;                              //根据op和funct判断是否为移位指令
    assign Jrn = ((Opcode==6'b000000)&&(Function_opcode==6'b001000)) ? 1'b1 : 1'b0;                 //根据op和funct判断是否为jr指令

    assign I_format = (Opcode[5:3]==3'b001)?1'b1:1'b0;	     //根据op判断是否为I型指令（除lw、sw、beq、bne）
    assign Lw = (Opcode==6'b100011)? 1'b1:1'b0;              //根据op判断是否为lw指令
    assign Sw = (Opcode==6'b101011)? 1'b1:1'b0;		 //根据op判断是否为sw指令    
    assign Branch = (Opcode==6'b000100)?1'b1:1'b0;            //根据op判断是否为beq指令  
    assign nBranch = (Opcode==6'b000101)?1'b1:1'b0;           //根据op判断是否为bne指令

    assign Jmp = (Opcode==6'b000010)?1'b1:1'b0;	     //根据op判断是否为j指令      
    assign Jal = (Opcode==6'b000011)?1'b1:1'b0;		       //根据op判断是否为jal指令 

    assign ALUOp = {(R_format || I_format),(Branch || nBranch)};  // 是R_format或I_format指令则1位为1，是beq、bne指令则0位为1
    assign ALUSrc = (I_format || Lw || Sw);             //需要选择立即数作为第二操作数的指令
    assign RegWrite = (R_format || I_format || Lw || Jal);             // 需要写寄存器的指令
    assign MemWrite = Sw;          // 需要写存储器的指令
    assign MemtoReg = Lw;         // 需要从端口或存储器读数据到寄存器的指令

endmodule
