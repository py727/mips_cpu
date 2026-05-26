`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module Executs32(Read_data_1,Read_data_2,Sign_extend,Function_opcode,Opcode,ALUOp,Shamt,ALUSrc,I_format,PC_plus_4,Zero,Sftmd,ALU_Result,Add_Result);
    input[31:0]  Read_data_1;		// 从译码单元的Read_data_1中来
    input[31:0]  Read_data_2;		// 从译码单元的Read_data_2中来
    input[31:0]  Sign_extend;		// 从译码单元来的扩展后的立即数
    input[5:0]   Function_opcode;  	// 取指单元来的R类型指令功能码，r-form instructions[5:0]
    input[5:0]   Opcode;  		// 取指单元来的操作码，instructions[31:26]
    input[1:0]   ALUOp;          	   // 来自控制单元的运算指令控制编码
    input[4:0]   Shamt;           // 来自取指单元的instruction[10:6]，指定移位次数
    input  	     Sftmd;          	  // 来自控制单元，为1表明是移位指令
    input        ALUSrc;          	  // 来自控制单元，为1表明第二个操作数是立即数（beq，bne除外）
    input        I_format;        	  // 来自控制单元，为1表明是除beq, bne, LW, SW之外的I-类型指令
    input[31:0]  PC_plus_4;    	     // 来自取指单元的PC+4
    output       Zero;           	   // 为1表明计算值为0 
    output[31:0] ALU_Result;               // 计算的数据结果
    output[31:0]  Add_Result    ;              // 计算的地址结果        

    wire[31:0] Ainput,Binput;         // ALU的A和B端口输入
    //ALU_Op是对指令的第一级控制，Exe_code和ALU_ctl构成对指令的第二级控制
    wire[5:0] Exe_code;             // 当I_format=1时， Exe_code等于操作码的低3位做0扩展到6位；其他时候Exe_code等于指令功能码
    wire[2:0] ALU_ctl;                // 生成一个组合码，用于对指令分类
    reg[31:0] Sinput;                   // ALU的移位端口输入
    reg[31:0] ALU_output_mux;     // 根据ALU_ctl生成ALU的中间结果
    wire[2:0] Sftm;                     // 移位指令实际有用的只有低三位
    reg[31:0] ALU_Result;               // 计算的数据结果

    assign Ainput = Read_data_1;                  // 为ALU的A端口赋值
    assign Binput = (ALUSrc == 0) ? Read_data_2 : Sign_extend[31:0];     // 为ALU的B端口赋值，ALUSrc为1时赋立即数，否则赋寄存器中的数
    assign Exe_code = (I_format==0) ? Function_opcode : {3'b000,Opcode[2:0]};   //根据Exe_code的定义给出

    assign ALU_ctl[0] = (Exe_code[0] | Exe_code[3]) & ALUOp[1];
    assign ALU_ctl[1] = ((!Exe_code[2]) | (!ALUOp[1]));
    assign ALU_ctl[2] = (Exe_code[1] & ALUOp[1]) | ALUOp[0];
    always @* begin
        case(ALU_ctl)
            3'b000:ALU_output_mux = Ainput & Binput;    // and，andi
            3'b001:ALU_output_mux = Ainput | Binput;   // or，ori
            3'b010:ALU_output_mux = Ainput + Binput;  // add，addi，lw，sw。lw，sw指令的组合码和add一样，但lw与sw两指令的主要功能在译码单元完成，而执行单元只是负责计算地址，所以在执行部件中，其运算功能和add指令等同，都是做加法，因此不必做区分。
            3'b011:ALU_output_mux = Ainput + Binput;  // addu，addiu
            3'b100:ALU_output_mux = Ainput ^ Binput;   // xor，xori
            3'b101:ALU_output_mux = ~(Ainput | Binput);  // nor，lui。后续需区分nor和lui。
            3'b110:ALU_output_mux = Ainput - Binput;  // sub，slti，beq，bne。beq、bne指令的组合码和sub一样，但执行都需要做减法，会用Zero的值作为beq和bne信号的判断条件，因此不必做区分；后续需区分sub和slti。
            3'b111:ALU_output_mux = Ainput - Binput;  // subu，sltiu，slt，sltu。后续需区分subu和slt、sltu和sltiu。
            default:ALU_output_mux = 32'h00000000;
        endcase
    end

    assign Sftm = Function_opcode[2:0];   // 取Function_opcode低三位
    always @* begin  // 6种移位指令
       if(Sftmd)
        case(Sftm[2:0])
            3'b000:Sinput = Binput << Shamt;               //Sll
            3'b010:Sinput = Binput >> Shamt;               //Srl
            3'b011:Sinput = $signed(Binput) >>> Shamt;      //Sra，需强调是有符号数
            3'b100:Sinput = Binput << Ainput[4:0];              //Sllv
            3'b110:Sinput = Binput >> Ainput[4:0];              //Srlv
            3'b111:Sinput = $signed(Binput) >>> Ainput[4:0];     //Srav，需强调是有符号数
            default:Sinput = Binput;
        endcase
       else Sinput = Binput;
    end

    always @* begin                      //完成运算结果输出
        // 处理 slt, sltu, slti, sltiu 指令
        if(((ALU_ctl==3'b111) && (Exe_code[3]==1)) || ((ALU_ctl[2:1]==2'b11) && (I_format==1))) begin
            // 无符号和有符号比较：sltu和sltiu的 Exe_code[0] 都是 1
            if(Exe_code[0] == 1'b1) 
                // 无符号比较 (sltu, sltiu)
                ALU_Result = (Ainput < Binput) ? 32'h00000001 : 32'h00000000;
            else
                // 有符号比较 (slt, slti)
                ALU_Result = ($signed(Ainput) < $signed(Binput)) ? 32'h00000001 : 32'h00000000;
        end
        else if((ALU_ctl==3'b101) && (I_format==1))
            ALU_Result = {Binput[15:0],16'b0000000000000000};   // lui指令
        else if(Sftmd==1) 
            ALU_Result = Sinput;                                // 移位指令
        else
            ALU_Result = ALU_output_mux[31:0];                  // 其他所有情况
    end
        
    assign Add_Result = PC_plus_4 + {Sign_extend[29:0],2'b00};        //算出beq和bne的PC值  
    assign Zero = (ALU_output_mux[31:0]== 32'h00000000) ? 1'b1 : 1'b0;

endmodule