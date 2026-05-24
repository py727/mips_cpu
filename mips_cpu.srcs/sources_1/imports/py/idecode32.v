`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module Idecode32(read_data_1,read_data_2,Instruction,read_data,ALU_result,Jal,RegWrite,MemtoReg,RegDst,Sign_extend,clock,reset,opcplus4);
    input[31:0]  Instruction;               // 来自取值模块
    input[31:0]  read_data;   	      //  从DATA RAM or I/O port取出的数据
    input[31:0]  ALU_result;   	   // 从执行单元来的运算的结果，需要扩展立即数到32位
    input[31:0]  opcplus4;                 // 来自取指单元，JAL中用
    input        Jal;                       //  来自控制单元，为1说明是JAL指令 
    input        RegDst;                    //  来自控制单元，为1表明目的寄存器是rd，否则目的寄存器是rt
    input        RegWrite;                  // 来自控制单元，为1表明该指令需要写寄存器
    input        MemtoReg;              // 来自控制单元，为1表明该指令需要从存储器写寄存器
    input        clock,reset;                // 时钟和复位
    output[31:0] read_data_1;               // 输出的第一操作数
    output[31:0] read_data_2;               // 输出的第二操作数
    output[31:0] Sign_extend;               // 扩展后的32位立即数
    
    reg[31:0] register[0:31];		 //寄存器组共32个32位寄存器
    reg[4:0] write_register_address;        // 要写的寄存器的号
    reg[31:0] write_data;                   // 要写寄存器的数据放这里
    wire[5:0] opcode;                       // 指令码(op)
    wire[4:0] read_register_1_address;    // 要读的第一个寄存器的号(rs)
    wire[4:0] read_register_2_address;     // 要读的第二个寄存器的号(rt)
    wire[4:0] write_register_address_1;   // r-form指令要写的寄存器的号(rd)
    wire[4:0] write_register_address_0;    // i-form指令要写的寄存器的号(rt)
    wire[15:0] Instruction_immediate_value;  // 指令中的立即数(immediate)
    wire sign;                                       //取符号位的值
    integer i;                                         //循环变量
    
    assign opcode = Instruction[31:26];		                //op
    assign read_register_1_address = Instruction[25:21];   	//rs
    assign read_register_2_address = Instruction[20:16];         //rt
    assign write_register_address_1 = Instruction[15:11];	//rd(r-form)
    assign write_register_address_0 = Instruction[20:16];	//rt(i-form)
    assign Instruction_immediate_value = Instruction[15:0];	//immediate(i-form)
    
    assign read_data_1 = register[read_register_1_address];     //读第一个寄存器
    assign read_data_2 = register[read_register_2_address];     //读第二个寄存器
    
    always @* begin                                //指定不同指令下的目标寄存器
        if((RegDst==1) && (Jal==0))
            write_register_address = write_register_address_1;      //r-form，指定rd寄存器(15-11)  
        else if((RegDst==0) && (Jal==1))
            write_register_address = 5'b11111;            	//JAL 指令，指定最后一个寄存器$31
        else  
            write_register_address  = write_register_address_0;          //i-form，指定rt寄存器(20-16)
    end

    always @* begin            //获得要写入寄存器的数据
        if((MemtoReg==0)&& (Jal== 0)) 
            write_data = ALU_result[31:0];                             //不是LW and IO, 也不是JAL指令，写入的是运算器结果数据
        else if((MemtoReg==0)&& (Jal== 1)) 
            write_data = opcplus4;                                            //不是LW，但是是jal，写入的是下一条指令地址(PC+4)
        else
            write_data = read_data;                                       //是LW指令，写入的是存储器中的数据
    end

    always @(posedge clock) begin       // 对目标寄存器的写操作
        if(reset==1) begin              // 初始化寄存器组
                for(i=0;i<32;i=i+1)
                  register[i] <= i;
        end
        else if(RegWrite==1) begin
        register[write_register_address[4:0]] <= write_data;
        end
    end
   
    assign sign = Instruction_immediate_value[15];              //确定符号位
    assign Sign_extend[31:0] = ((opcode==6'b001100)     // andi
                      ||(opcode==6'b001101)             // ori
                      ||(opcode==6'b001110)             // xori
                      ||(opcode==6'b001011))            // sltiu
                      ? {16'h0000,Instruction_immediate_value[15:0]}  // 立即数0扩展
                      :{sign,sign,sign,sign,sign,sign,sign,sign,sign,sign,sign,sign,sign,sign,sign,sign,Instruction_immediate_value[15:0]};  //立即数符号扩展

endmodule
