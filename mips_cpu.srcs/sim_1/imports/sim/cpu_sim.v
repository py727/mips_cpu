`timescale 1ns / 1ps

module cpu_sim();
    reg clk = 0;
    reg rst = 1;
    
    motherboard u (.clk(clk), .rst(rst));
    
    // 100MHz 始终生成
    always #5 clk = ~clk;

    initial begin
        #1500 rst = 0;
    end

    integer pass_count = 0;
    integer fail_count = 0;
    reg [31:0] check_pc;

    // 自动检查任务：增加 #2 延迟，确保在写回后再读
    task assert_reg(input integer reg_num, input [31:0] expected_val, input [255:0] inst_name);
        reg [31:0] actual_val;
        begin
            actual_val = u.idecode.register[reg_num];
            if (actual_val === expected_val) begin
                $display("[PASS] %s | Register $%0d = 0x%h", inst_name, reg_num, actual_val);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %s | Register $%0d Expected %h, Got %h", inst_name, reg_num, expected_val, actual_val);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // 监测每一个时钟周期
    always @(negedge u.clock) begin
        // 在下降沿，寄存器刚好完成写入，PC 刚好完成更新
        // 我们等待 2ns，进入平稳期后再检查上一条指令的结果
        #2; 
        if (!rst) begin
            // 我们检查刚才刚刚执行完的那条指令（即 PC 变动前的那个地址）
            // 注意：由于 PC 已经在下降沿变到了下一个值，我们要查的是 (current_pc_in_ifetch - 4)
            check_pc = (u.ifetch.PC - 4) & 32'h0000_FFFF;

            case (check_pc)
                32'h0000_0000: assert_reg(1, 32'h1234_0000, "LUI  ");
                32'h0000_0004: assert_reg(1, 32'h1234_5678, "ORI  ");
                32'h0000_0008: assert_reg(2, 32'd10,        "ADDI ");
                32'h0000_000c: assert_reg(3, 32'd20,        "ADDIU");
                32'h0000_0010: assert_reg(4, 32'h0000_0078, "ANDI ");
                32'h0000_0014: assert_reg(5, 32'd13,        "XORI ");
                32'h0000_0018: assert_reg(6,  32'd30,       "ADD  ");
                32'h0000_001c: assert_reg(7,  32'd30,       "ADDU ");
                32'h0000_0020: assert_reg(8,  32'd10,       "SUB  ");
                32'h0000_0024: assert_reg(9,  32'd10,       "SUBU ");
                32'h0000_0028: assert_reg(10, 32'd30,       "AND  ");
                32'h0000_002c: assert_reg(11, 32'd30,       "OR   ");
                32'h0000_0030: assert_reg(12, 32'd20,       "XOR  ");
                32'h0000_0034: assert_reg(13, ~32'd10,      "NOR  ");
                32'h0000_0038: assert_reg(14, 32'd40,       "SLL  ");
                32'h0000_003c: assert_reg(15, 32'd5,        "SRL  ");
                32'h0000_0048: assert_reg(17, 32'hfffffffc, "SRA  ");
                32'h0000_0050: assert_reg(19, 32'd40,       "SLLV ");
                32'h0000_0054: assert_reg(20, 32'd2,        "SRLV ");
                32'h0000_0058: assert_reg(21, 32'hfffffffe, "SRAV ");
                32'h0000_005c: assert_reg(22, 32'd1,        "SLT  ");
                32'h0000_0060: assert_reg(23, 32'd0,        "SLTI ");
                32'h0000_0064: assert_reg(24, 32'd1,        "SLTU ");
                32'h0000_0068: assert_reg(25, 32'd0,        "SLTIU");
                32'h0000_0070: assert_reg(26, 32'd30,       "LW   ");

                // 特殊检查：BEQ 是否跳过了 0x74 (addi $2, 99)
                32'h0000_0074: if(u.idecode.register[2] == 99) $display("[FAIL] BEQ Failed to jump!");

                // 检查 JAL 返回地址是否正确 ($31 应为 0x84)
                32'h0000_0080: #1 $display("[INFO] JAL Executed. Checking Link Reg...");
                32'h0000_0088: assert_reg(31, 32'h0000_0084, "JAL Link");

                // 程序结束点
                32'h0000_0098: begin
                    assert_reg(29, 32'd255, "FINAL");
                    $display("\nSummary: Passed: %d, Failed: %d", pass_count, fail_count);
                    $stop;
                end
            endcase
        end
    end
endmodule