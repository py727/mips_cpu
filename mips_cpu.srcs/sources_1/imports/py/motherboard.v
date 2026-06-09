`timescale 1ns / 1ps

module motherboard(rst, clk, d);
    input rst;               // 板上的Reset信号，高电平复位
    input clk;               // 板上的100MHz时钟信号
    output d;                // 这里的 d 通常可以接一个 LED 或者作为调试输出
    
    wire clock;              
    wire[31:0] write_data;   
    wire[31:0] pc_plus_4;   
    wire[31:0] read_data_1;  
    wire[31:0] read_data_2;  
    wire[31:0] sign_extend;  
    wire[31:0] add_result;   
    wire[31:0] alu_result;   
    wire[31:0] read_data;    
    wire alusrc;
    wire branch;
    wire nbranch, jmp, jal, jrn, i_format;
    wire regdst;
    wire regwrite;
    wire zero;
    wire memwrite;
    wire memtoreg;
    wire sftmd;
    wire[1:0] aluop;
    wire[31:0] instruction;
    wire[31:0] opcplus4;
    
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