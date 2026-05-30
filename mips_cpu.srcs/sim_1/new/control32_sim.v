`timescale 1ns / 1ps

module control32_sim();
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
        $display("==========================================================================");
        $display("                  Control32 Module Rigorous Simulation                    ");
        $display("   OP   | FUNCT | Jrn Dst Src M2R Wrt MW Br nBr Jmp Jal I_F Sft | ALUOp   ");
        $display("==========================================================================");

        // 1. ADD (R-format, Not shift, Not Jr)
        Opcode = 6'b000000; Function_opcode = 6'b100000; #10;
        $display(" ADD    | 100000|  %b   %b   %b   %b   %b  %b  %b   %b   %b   %b   %b   %b  |  %b  (Exp: RegW=1, Dst=1, ALUOp=10)", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        // 2. SLL (R-format, Shift)
        Opcode = 6'b000000; Function_opcode = 6'b000000; #10;
        $display(" SLL    | 000000|  %b   %b   %b   %b   %b  %b  %b   %b   %b   %b   %b   %b  |  %b  (Exp: Sft=1, RegW=1)", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        // 3. JR (R-format spec, Jrn=1, RegWrite=0)
        Opcode = 6'b000000; Function_opcode = 6'b001000; #10;
        $display(" JR     | 001000|  %b   %b   %b   %b   %b  %b  %b   %b   %b   %b   %b   %b  |  %b  (Exp: Jrn=1, RegW=0)", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        // 4. ADDI (I_format)
        Opcode = 6'b001000; Function_opcode = 6'bxxxxxx; #10;
        $display(" ADDI   | XXXXXX|  %b   %b   %b   %b   %b  %b  %b   %b   %b   %b   %b   %b  |  %b  (Exp: I_F=1, ALUSrc=1, RegW=1, ALUOp=10)", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        // 5. LW (Memory Read)
        Opcode = 6'b100011; Function_opcode = 6'bxxxxxx; #10;
        $display(" LW     | XXXXXX|  %b   %b   %b   %b   %b  %b  %b   %b   %b   %b   %b   %b  |  %b  (Exp: ALUSrc=1, M2R=1, RegW=1, ALUOp=00)", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        // 6. SW (Memory Write)
        Opcode = 6'b101011; Function_opcode = 6'bxxxxxx; #10;
        $display(" SW     | XXXXXX|  %b   %b   %b   %b   %b  %b  %b   %b   %b   %b   %b   %b  |  %b  (Exp: ALUSrc=1, MW=1, RegW=0, ALUOp=00)", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        // 7. BEQ (Branch)
        Opcode = 6'b000100; Function_opcode = 6'bxxxxxx; #10;
        $display(" BEQ    | XXXXXX|  %b   %b   %b   %b   %b  %b  %b   %b   %b   %b   %b   %b  |  %b  (Exp: Br=1, ALUOp=01)", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        // 8. JAL (Jump and Link)
        Opcode = 6'b000011; Function_opcode = 6'bxxxxxx; #10;
        $display(" JAL    | XXXXXX|  %b   %b   %b   %b   %b  %b  %b   %b   %b   %b   %b   %b  |  %b  (Exp: Jal=1, RegW=1)", 
                  Jrn, RegDST, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, nBranch, Jmp, Jal, I_format, Sftmd, ALUOp);

        $display("==========================================================================");
        $stop;
    end
endmodule