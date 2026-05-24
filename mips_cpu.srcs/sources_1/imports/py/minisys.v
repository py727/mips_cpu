`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module minisys(rst,clk,d);
    input rst;               //板上的Reset信号，高电平复位
    input clk;               //板上的100MHz时钟信号
    output d;
    
    wire clock;              //clock: 分频后时钟供给系统
    wire[31:0] write_data;   //写RAM或IO的数据
    wire[31:0] pc_plus_4;   
    wire[31:0] read_data_1;  
    wire[31:0] read_data_2;  
    wire[31:0] sign_extend;  
    wire[31:0] add_result;   
    wire[31:0] alu_result;   
    wire[31:0] read_data;    //RAM中读取的数据
    wire alusrc;
    wire branch;
    wire nbranch,jmp,jal,jrn,i_format;
    wire regdst;
    wire regwrite;
    wire zero;
    wire memwrite;
    wire memtoreg;
    wire sftmd;
    wire[1:0] aluop;
    wire[31:0] instruction;
    wire[31:0] opcplus4;
    
    cpuclk cpuclk(
        .clk_in1(clk),    //100MHz
        .clk_out1(clock)    //cpuclock
    );

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
                      
    Executs32 execute(
        .Read_data_1(read_data_1),
        .Read_data_2(read_data_2),
        .Sign_extend(sign_extend),
        .Function_opcode(instruction[5:0]),
        .Opcode(instruction[31:26]),
        .Shamt(instruction[10:6]),
        .Sftmd(sftmd),
        .ALUOp(aluop),
        .ALUSrc(alusrc),
        .ALU_Result(alu_result),
        .Add_Result(add_result),
        .I_format(i_format),
        .Zero(zero),
        .PC_plus_4(pc_plus_4)
     );
    
    dmemory32 memory(
        .read_data(read_data),
        .address(alu_result),
        .write_data(read_data_2),
        .Memwrite(memwrite),
        .clock(clock)    
    );
endmodule
