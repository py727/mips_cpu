`timescale 1ns / 1ps

module control32_full_test();
    reg [5:0] Opcode;
    reg [5:0] Function_opcode;
    
    wire Jrn, RegDST, ALUSrc, MemtoReg, RegWrite;
    wire MemWrite, Branch, nBranch, Jmp, Jal;
    wire I_format, Sftmd;
    wire [1:0] ALUOp;

    control32 U_ctrl (
        .Opcode(Opcode),
        .Function_opcode(Function_opcode),
        .Jrn(Jrn),
        .RegDST(RegDST),
        .ALUSrc(ALUSrc),
        .MemtoReg(MemtoReg),
        .RegWrite(RegWrite),
        .MemWrite(MemWrite),
        .Branch(Branch),
        .nBranch(nBranch),
        .Jmp(Jmp),
        .Jal(Jal),
        .I_format(I_format),
        .Sftmd(Sftmd),
        .ALUOp(ALUOp)
    );

    initial begin
        $display("==================================================================================================");
        $display("                           Control32 完整指令测试");
        $display("指令    | Jrn | Dst | Src | M2R | Wrt | MW  | Br  | nBr | Jmp | Jal | I_F | Sft | ALUOp | 说明");
        $display("--------------------------------------------------------------------------------------------------");
        
        //==========================================
        // R型运算指令 (Opcode=000000, Function决定具体操作)
        //==========================================
        
        // ADD  rd = rs + rt
        Opcode = 6'b000000; Function_opcode = 6'b100000; #10;
        $display("add     |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b   | RegW=1, ALUOp=10", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        // ADDU rd = rs + rt (unsigned)
        Opcode = 6'b000000; Function_opcode = 6'b100001; #10;
        $display("addu    |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b   | RegW=1, ALUOp=10", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        // SUB  rd = rs - rt
        Opcode = 6'b000000; Function_opcode = 6'b100010; #10;
        $display("sub     |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b   | RegW=1, ALUOp=10", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        // SUBU rd = rs - rt (unsigned)
        Opcode = 6'b000000; Function_opcode = 6'b100011; #10;
        $display("subu    |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b   | RegW=1, ALUOp=10", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        // AND  rd = rs & rt
        Opcode = 6'b000000; Function_opcode = 6'b100100; #10;
        $display("and     |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b   | RegW=1, ALUOp=10", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        // OR   rd = rs | rt
        Opcode = 6'b000000; Function_opcode = 6'b100101; #10;
        $display("or      |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b   | RegW=1, ALUOp=10", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        // XOR  rd = rs ^ rt
        Opcode = 6'b000000; Function_opcode = 6'b100110; #10;
        $display("xor     |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b   | RegW=1, ALUOp=10", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        // NOR  rd = ~(rs | rt)
        Opcode = 6'b000000; Function_opcode = 6'b100111; #10;
        $display("nor     |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b   | RegW=1, ALUOp=10", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        // SLT  rd = (rs < rt) ? 1 : 0 (signed)
        Opcode = 6'b000000; Function_opcode = 6'b101010; #10;
        $display("slt     |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b   | RegW=1, ALUOp=10", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        // SLTU rd = (rs < rt) ? 1 : 0 (unsigned)
        Opcode = 6'b000000; Function_opcode = 6'b101011; #10;
        $display("sltu    |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b   | RegW=1, ALUOp=10", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        //==========================================
        // R型移位指令
        //==========================================
        
        // SLL  rd = rt << shamt
        Opcode = 6'b000000; Function_opcode = 6'b000000; #10;
        $display("sll     |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b   | RegW=1, Sftmd=1", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        // SRL  rd = rt >> shamt (logical)
        Opcode = 6'b000000; Function_opcode = 6'b000010; #10;
        $display("srl     |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b   | RegW=1, Sftmd=1", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        // SRA  rd = rt >>> shamt (arithmetic)
        Opcode = 6'b000000; Function_opcode = 6'b000011; #10;
        $display("sra     |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b   | RegW=1, Sftmd=1", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        // SLLV rd = rt << rs[4:0]
        Opcode = 6'b000000; Function_opcode = 6'b000100; #10;
        $display("sllv    |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b   | RegW=1, Sftmd=1", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        // SRLV rd = rt >> rs[4:0]
        Opcode = 6'b000000; Function_opcode = 6'b000110; #10;
        $display("srlv    |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b   | RegW=1, Sftmd=1", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        // SRAV rd = rt >>> rs[4:0]
        Opcode = 6'b000000; Function_opcode = 6'b000111; #10;
        $display("srav    |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b   | RegW=1, Sftmd=1", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        //==========================================
        // R型跳转指令
        //==========================================
        
        // JR   pc = rs
        Opcode = 6'b000000; Function_opcode = 6'b001000; #10;
        $display("jr      |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b   | Jrn=1, RegW=0", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        //==========================================
        // I型运算指令 (Opcode[5:3]=001)
        //==========================================
        
        // ADDI rt = rs + imm (signed)
        Opcode = 6'b001000; Function_opcode = 6'b000000; #10;
        $display("addi    |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b   | I_F=1, ALUSrc=1", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        // ADDIU rt = rs + imm (unsigned)
        Opcode = 6'b001001; Function_opcode = 6'b000000; #10;
        $display("addiu   |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b   | I_F=1, ALUSrc=1", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        // ANDI rt = rs & imm
        Opcode = 6'b001100; Function_opcode = 6'b000000; #10;
        $display("andi    |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b   | I_F=1, ALUSrc=1", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        // ORI  rt = rs | imm
        Opcode = 6'b001101; Function_opcode = 6'b000000; #10;
        $display("ori     |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b   | I_F=1, ALUSrc=1", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        // XORI rt = rs ^ imm
        Opcode = 6'b001110; Function_opcode = 6'b000000; #10;
        $display("xori    |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b   | I_F=1, ALUSrc=1", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        // LUI  rt = imm << 16
        Opcode = 6'b001111; Function_opcode = 6'b000000; #10;
        $display("lui     |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b   | I_F=1, ALUSrc=1", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        // SLTI rt = (rs < imm) ? 1 : 0 (signed)
        Opcode = 6'b001010; Function_opcode = 6'b000000; #10;
        $display("slti    |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b   | I_F=1, ALUSrc=1", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        // SLTIU rt = (rs < imm) ? 1 : 0 (unsigned)
        Opcode = 6'b001011; Function_opcode = 6'b000000; #10;
        $display("sltiu   |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b   | I_F=1, ALUSrc=1", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        //==========================================
        // 访存指令
        //==========================================
        
        // LW   rt = mem[rs+imm]
        Opcode = 6'b100011; Function_opcode = 6'b000000; #10;
        $display("lw      |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b   | ALUSrc=1, M2R=1", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        // SW   mem[rs+imm] = rt
        Opcode = 6'b101011; Function_opcode = 6'b000000; #10;
        $display("sw      |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b   | ALUSrc=1, MW=1", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        //==========================================
        // 分支指令
        //==========================================
        
        // BEQ  if(rs==rt) pc = pc+4+imm
        Opcode = 6'b000100; Function_opcode = 6'b000000; #10;
        $display("beq     |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b   | Branch=1, ALUOp=01", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        // BNE  if(rs!=rt) pc = pc+4+imm
        Opcode = 6'b000101; Function_opcode = 6'b000000; #10;
        $display("bne     |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b   | nBranch=1, ALUOp=01", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        //==========================================
        // 跳转指令
        //==========================================
        
        // J    pc = {pc[31:28], imm, 2'b00}
        Opcode = 6'b000010; Function_opcode = 6'b000000; #10;
        $display("j       |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b   | Jmp=1", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        // JAL  $31 = pc+4; pc = {pc[31:28], imm, 2'b00}
        Opcode = 6'b000011; Function_opcode = 6'b000000; #10;
        $display("jal     |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b  |  %b   | Jmp=1, Jal=1, RegW=1", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        $display("==================================================================================================");
        $display("                                 测试完成");
        $display("==================================================================================================");
        $stop;
    end
endmodule