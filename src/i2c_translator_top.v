`timescale 1ns / 1ps

module i2c_translator_top(
    input wire clk,
    input wire rst_n,
    
    inout wire scl_host,
    inout wire sda_host,
    output wire scl_sensor,
    inout wire sda_sensor
    );
    
    localparam [6:0] VIRTUAL_ADDR = 7'h49;
    localparam [6:0] REAL_ADDR = 7'h48;
    
    wire [7:0] data_from_host;
    wire host_data_valid;
    wire rw_bit;
    wire stretch_req;
    
    wire [7:0] data_from_target;
    wire master_done;
    wire master_busy;
    
    reg start_master;
    reg [7:0] tx_data_to_target;
    
    assign scl_host = (stretch_req) ? 1'b0:1'bz;
    
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            start_master<= 0;
            tx_data_to_target<=0;
        end else begin
            if((host_data_valid && !rw_bit && !master_busy) || (stretch_req && rw_bit && !master_busy && !start_master))begin
                tx_data_to_target <= data_from_host;
                start_master <=1;
            end else begin
                start_master<=0;
            end 
           end
          end
          
          i2c_slave#(.VIRTUAL_ADDR(VIRTUAL_ADDR))u_slave(
            .clk(clk), .rst_n(rst_n),
            .scl_in(scl_host), .sda_inout(sda_host),
            .rx_data(data_from_host), .rx_valid(host_data_valid),
            .rw_bit_out(rw_bit), .stretch_scl(stretch_req),
            .tx_data_in(data_from_target), .master_tx_done(master_done)
          );
          
          i2c_master#(.REAL_ADDR(REAL_ADDR))u_master(
          .clk(clk), .rst_n(rst_n),
          .start_tx(start_master), .rw_mode(rw_bit), .tx_data(tx_data_to_target),
          .rx_data(data_from_target), .rx_valid(), .scl_out(scl_sensor),
          .sda_inout(sda_sensor), .busy(master_busy), .tx_done(master_done)
          );
endmodule

