`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.05.2026 22:58:54
// Design Name: 
// Module Name: tb_i2c_translator
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_i2c_translator();

    reg clk = 0;
    reg rst_n = 0;
    reg scl_host_drv = 1;
    reg sda_host_drv = 1;
    
    wire scl_host, sda_host;
    wire scl_sensor, sda_sensor;
    
    assign scl_host = scl_host_drv ? 1'bz:1'b0; 
    assign sda_host = sda_host_drv ? 1'bz:1'b0;
    
    pullup(scl_host); pullup(sda_host);
    pullup(scl_sensor); pullup(sda_sensor);
    
    i2c_translator_top dut(
        .clk(clk), .rst_n(rst_n),
        .scl_host(scl_host), .sda_host(sda_host),
        .scl_sensor(scl_sensor), .sda_sensor(sda_sensor)
        );
        
    mock_i2c_device #(.MY_ADDR(7'h48))dev1(
        .scl(scl_host), .sda(sda_host)
    );
    mock_i2c_device #(.MY_ADDR(7'h48)) dev2(
        .scl(scl_sensor), .sda(sda_sensor)
    );
    
    always #5 clk = ~clk;
    
    task i2c_start;
        begin
            scl_host_drv = 1; sda_host_drv = 1; #5000;
            sda_host_drv = 0; #5000;
            scl_host_drv = 0; #5000;
        end
    endtask
    
    task i2c_stop;
        begin
            scl_host_drv = 0; sda_host_drv = 0; #5000;
            sda_host_drv = 1; #5000;
            scl_host_drv = 1; #5000;
        end
    endtask
    
    task i2c_send_byte(input[7:0] data);
        integer i;
        begin
            for(i = 7; i>=0;i=i-1)begin
                sda_host_drv = data[i]; #2500;
                scl_host_drv = 1; #2500;
                scl_host_drv = 0; #2500;
            end
            sda_host_drv = 1; #2500;
            scl_host_drv = 1; #5000;
            scl_host_drv = 0; #2500;
        end
    endtask
    
    initial begin
        $dumpfile("dump.vcd"); $dumpvars(0, tb_i2c_translator);
        
        #100 rst_n = 1; #1000;
        
        $display("****Transaction 1: Master talks to 0x48 directly****");
        
        i2c_start();
        i2c_send_byte(8'h90);
        i2c_send_byte(8'hAA);
        i2c_stop();
        #20000;
        
        $display("****Transaction 1: Master talks to Virtual 0x49****");
        
        i2c_start();
        i2c_send_byte(8'h92);
        i2c_send_byte(8'hBB);
        i2c_stop();
        
        #100000;
        $display("Simulation Complete");
        $finish;
    end
endmodule

