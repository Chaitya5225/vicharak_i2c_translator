`timescale 1ns / 1ps

module mock_i2c_device#(
    parameter[6:0] MY_ADDR =7'h48
)(
    inout wire scl,
    inout wire sda
    );
    
    reg[7:0]shift_reg = 0;
    reg[3:0] bit_cnt = 0;
    reg sda_out = 1;
    reg active = 0;
    
    assign sda = sda_out ? 1'bz:1'b0;
    
    always@(posedge scl)begin
        shift_reg<= {shift_reg[6:0], sda};
        bit_cnt <= bit_cnt+1;
        if(bit_cnt == 8) bit_cnt<=1;
      end
      
      always@(negedge scl)begin
        if(bit_cnt == 8 && shift_reg[7:1] == MY_ADDR)begin
            sda_out<=0;
            active<=1;
        end else if(bit_cnt == 8 && active)begin
            sda_out<= 0;
        end else begin
            sda_out<= 1;
        end 
        end
endmodule

