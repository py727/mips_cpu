`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module Ifetc32(Instruction,PC_plus_4_out,Add_result,Read_data_1,Branch,nBranch,Jmp,Jal,Jrn,Zero,clock,reset,opcplus4);
    input[31:0]  Add_result;                      // 来自执行单元，算出的跳转地址
    input[31:0]  Read_data_1;                    // 来自译码单元，jr指令用的地址
    input        Branch;                  // 来自控制单元，为1表明是Beq指令
    input        nBranch;                  // 来自控制单元，为1表明是Bne指令
    input        Jmp;                     // 来自控制单元，为1表明是J指令
    input        Jal;                      // 来自控制单元，为1表明是Jal指令
    input        Jrn;                     // 来自控制单元，为1表明当前指令是jr
    input        Zero;                    //来自执行单元，为1表明计算值为0
    input        clock,reset;                //时钟(23MHz)与复位(高电平有效)
    output[31:0]      Instruction;		          // 输出指令到其他模块
    output[31:0]      PC_plus_4_out;            // (pc+4)送执行单元
    output[31:0]      opcplus4;                  // JAL指令专用的PC+4
    
    wire [31:0] PC_plus_4;                        //PC+4
    reg [31:0] PC;                               // 当前指令的PC
    reg [31:0] next_PC;		// 下条指令的PC（不一定是PC+4)
    reg[31:0] opcplus4;                         // JAL指令专用的PC+4
    
    // ROM Pinouts
     prgrom instmem(
        .clka(clock),         // input wire clka
        .addra(PC[15:2]),     // input wire [13 : 0] addra
        .douta(Instruction)         // output wire [31 : 0] douta
    );   

    assign PC_plus_4[31:2] = PC[31:2]+1;     // 此处＋1实际上是＋4，因为这里低2位始终为00，＋1加在D2位上
    assign PC_plus_4[1:0] =2'b00;
    assign PC_plus_4_out = PC_plus_4[31:0];    // PC＋4送到执行单元，以便执行单元在必要的时候算出ADDRESULT

    always @* begin  // 对beq, bne, jr指令的处理
        if(((Branch == 1) && (Zero == 1)) || ((nBranch == 1) && (Zero == 0)))
            next_PC = Add_result;          //  beq或bne指令，计算出的新PC地址
        else if(Jrn == 1)
            next_PC = Read_data_1[31:0];      //jr指令，PC地址由寄存器给出
        else  next_PC = PC_plus_4;         // 其他时候都是PC<-PC+4
    end
    
always @(negedge clock) begin  // 对J，Jal指令和reset的处理
         if(reset == 1) begin
             PC <= 32'b0;
         end else begin
           if(Jmp == 1) begin
                // J指令：使用PC+4的高4位拼接指令中的26位立即数，再补2个0
                PC <= {4'b0000, Instruction[25:0], 2'b00};  
           end else if(Jal == 1) begin
                // JAL指令：先保存PC+4到$31寄存器(即$ra)
               opcplus4 <= PC_plus_4;  
                // 再更新PC，与J指令相同的寻址方式
                PC <= {4'b0000, Instruction[25:0], 2'b00};  
           end else begin
                PC <= next_PC; // 其他指令使用默认PC更新
           end
         end
    end

endmodule