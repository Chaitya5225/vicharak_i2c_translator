`timescale 1ns/1ps

module i2c_master #(
    parameter [6:0] REAL_ADDR = 7'h48,
    parameter CLK_HALF_PERIOD = 500
    )(
      input wire clk,
      input wire rst_n,
      input wire start_tx,
      input wire rw_mode,
      input wire [7:0] tx_data,
      
      output reg [7:0] rx_data,
      output reg rx_valid,
      output reg scl_out,
      inout wire sda_inout,
      output reg busy,
      output reg tx_done 
    );
    
    localparam IDLE = 3'd0;
    localparam START = 3'd1;
    localparam TX_ADDR = 3'd2;
    localparam DATA_PHASE = 3'd3;
    localparam STOP = 3'd4;
    
    reg [2:0] state;
    reg [7:0] shift_reg;
    reg [3:0] bit_cnt;
    reg is_read;
    
    reg sda_out;
    assign sda_inout = (sda_out == 1'b0) ? 1'b0: 1'bz;
    reg [15:0] clk_cnt;
    reg scl_en;
    
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            clk_cnt <= 0; scl_en<= 0;
        end else if(state != IDLE)begin
            if(clk_cnt == CLK_HALF_PERIOD - 1)begin
                clk_cnt <= 0; scl_en<=1;
            end else begin
                clk_cnt <= clk_cnt + 1; scl_en<=0;
            end
            end else begin
                clk_cnt<= 0; scl_en<=0;
            end 
           end
           
      always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            state <= IDLE; scl_out<=1; sda_out<=1;
            busy <= 0; bit_cnt<= 0; rx_valid<= 0; rx_data<= 0; tx_done<=0;
         end else begin
           rx_valid<= 0; tx_done<= 0;
           case(state) 
            IDLE:begin
                scl_out <= 1; sda_out<=1;busy<=0;
                if(start_tx)begin
                    shift_reg<= tx_data;
                    is_read<= rw_mode;
                    busy<=1;
                    state<=START;
                end
             end
             START: begin
                if(scl_en)begin
                    sda_out<= 0; state<= TX_ADDR; bit_cnt<=0;
                    end
                end
              TX_ADDR:begin
                if(scl_en)begin
                scl_out <= ~scl_out;
                if(!scl_out)begin
                    if(bit_cnt<7) sda_out<= REAL_ADDR[6 - bit_cnt];
                        else sda_out <= is_read;
                 end else begin
                 if(bit_cnt == 8) begin
                    state<= DATA_PHASE; bit_cnt<=0;
                 end else bit_cnt<=bit_cnt +1;
                 end 
                 end
                 end
               DATA_PHASE:begin
                   if(scl_en)begin
                    scl_out<= ~scl_out;
                    if(!scl_out)begin
                        if(!is_read)begin
                            if(bit_cnt<8)sda_out<=shift_reg[7 - bit_cnt];
                            else sda_out <= 1;
                            end else sda_out <= 1;
                     end else begin 
                     if(is_read && bit_cnt < 8) rx_data[7 - bit_cnt] <= sda_inout;
                     
                     if(bit_cnt == 8)begin
                        if(is_read)rx_valid<=1;
                        tx_done<=1;
                        state<= STOP;
                        end else bit_cnt <= bit_cnt + 1;
                        end
                        end
                        end
                 STOP: begin
                    if (scl_en) begin
                        if (bit_cnt == 8) begin
                            //prepare SDA low
                            scl_out <= 0;
                            sda_out <= 0;
                            bit_cnt <= 9;
                        end else if (bit_cnt == 9) begin
                            // release SCL high
                            scl_out <= 1;
                            bit_cnt <= 10;
                        end else if (bit_cnt == 10) begin
                            //Valid STOP
                            sda_out <= 1;
                            state <= IDLE;
                        end
                    end
                end
            endcase
          end
        end                   
endmodule
