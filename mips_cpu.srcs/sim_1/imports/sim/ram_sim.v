`timescale 1ns / 1ps

module ram_sim();
    // 1. 信号定义
    reg [31:0] address;
    reg [31:0] write_data;
    reg        Memwrite;
    reg        clock;
    wire [31:0] read_data;

    // 2. 实例化被测模块
    dmemory32 Uram (
        .read_data(read_data),
        .address(address),
        .write_data(write_data),
        .Memwrite(Memwrite),
        .clock(clock)
    );

    // 3. 时钟生成 (10MHz, 周期100ns)
    initial clock = 1'b0;
    always #50 clock = ~clock;

    // 4. 测试流程
    initial begin
        // 初始化
        address = 32'h0000_0000;
        write_data = 32'h0000_0000;
        Memwrite = 1'b0;
        
        $display("=========================================================");
        $display("           Start dmemory32 Rigorous Simulation           ");
        $display("=========================================================");

        // T1: 基础写入测试 (地址 0x0000)
        // 在上升沿准备数据，由于内部时钟取反，RAM将在接下来的下降沿捕获
        @(posedge clock);
        address = 32'h0000_0000;
        write_data = 32'hAAAA_BBBB;
        Memwrite = 1'b1;
        
        @(posedge clock);
        Memwrite = 1'b0; // 停止写入
        #10; // 等待片刻观察输出
        $display("[T1 Write/Read] Addr: 0x0, Data: %h (Expected: aaaabbbb)", read_data);

        // T2: 地址对齐测试 (4字节对齐)
        // 写入地址 0x0004，然后分别尝试读取 0x0004, 0x0005, 0x0006, 0x0007
        // 预期结果：由于 [15:2] 的存在，这四个地址读出的数据应该一模一样
        @(posedge clock);
        address = 32'h0000_0004;
        write_data = 32'h1234_5678;
        Memwrite = 1'b1;
        
        @(posedge clock);
        Memwrite = 1'b0;
        address = 32'h0000_0004; #20; $display("[T2 Align] Addr 0x4: %h", read_data);
        address = 32'h0000_0005; #20; $display("[T2 Align] Addr 0x5: %h", read_data);
        address = 32'h0000_0006; #20; $display("[T2 Align] Addr 0x6: %h", read_data);
        address = 32'h0000_0007; #20; $display("[T2 Align] Addr 0x7: %h (Expect all same)", read_data);

        // T3: 连续写入数据 (为后续验证做准备)
        // -------------------------------------------------------------
        @(posedge clock);
        address = 32'h0000_0008; 
        write_data = 32'hCCCC_DDDD; 
        Memwrite = 1'b1; // 开启写入
        
        @(posedge clock);
        address = 32'h0000_000C; 
        write_data = 32'hEEEE_FFFF; 
        // Memwrite 保持为 1
        
        @(posedge clock);
        Memwrite = 1'b0; // 写入完成，关闭写使能
        
        // -------------------------------------------------------------
        // T4: 验证读取 (确保刚才存进去的数据都能读出来)
        // -------------------------------------------------------------
        $display("--- Start Verification ---");

        // 验证地址 0x0
        @(posedge clock);
        address = 32'h0000_0000; 
        @(negedge clock); // 等待 RAM 内部 clk 上升沿触发读取
        #10; $display("[T4 Verify] Addr 0x0: %h (Expected: aaaabbbb)", read_data);

        // 验证地址 0x8
        @(posedge clock);
        address = 32'h0000_0008; 
        @(negedge clock); 
        #10; $display("[T4 Verify] Addr 0x8: %h (Expected: ccccdddd)", read_data);

        // 验证地址 0xC
        @(posedge clock);
        address = 32'h0000_000C; 
        @(negedge clock); 
        #10; $display("[T4 Verify] Addr 0xC: %h (Expected: eeeeffff)", read_data);

        $display("=========================================================");
        $display("                  Simulation Finished                    ");
        $display("=========================================================");
        $stop;
    end

endmodule