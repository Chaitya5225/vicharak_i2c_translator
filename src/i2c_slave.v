`timescale 1ns / 1ps

module i2c_slave#(
    parameter [6:0] VIRTUAL_ADDR = 7'h49
)(
    input wire clk,
    input wire rst_n,
    input wire scl_in,
    input wire sda_inout,
    
    output reg [7:0] rx_data,
    output reg rx_valid,
    output reg rw_bit_out,
    output reg stretch_scl,
    
    input wire [7:0] tx_data_in,
    input wire master_tx_done
);

    localparam IDLE = 3'd0;
    localparam RX_ADDR = 3'd1;
    localparam ACK_ADDR = 3'd2;
    localparam RX_PAYLOAD = 3'd3;
    localparam ACK_PAYLOAD = 3'd4;
    localparam WAIT_FETCH = 3'd5;
    localparam TX_PAYLOAD = 3'd6;
    
    reg [2:0] state;
    reg [7:0] shift_reg;
    reg [3:0] bit_cnt;
    
    reg sda_out;
    assign sda_inout = (sda_out == 1'b0) ? 1'b0 : 1'bz;
    
    reg scl_d, sda_d;
    always@(posedge clk)begin
        scl_d <= scl_in;
        sda_d <= sda_inout;
    end
    
    wire scl_rise = (scl_in && !scl_d);
    wire scl_fall = (!scl_in && scl_d);
    wire start_det = (scl_in && !sda_inout && sda_d);
    wire stop_det = (scl_in && sda_inout && !sda_d);
    
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            state <= IDLE; bit_cnt<= 0; shift_reg <= 0; sda_out <= 1;
            rx_valid<=0; rx_data<=0; rw_bit_out<= 0; stretch_scl<=0;
        end else begin
            rx_valid<=0;
            //asynchronous start/stop
            
            if(start_det)begin
                state<= RX_ADDR; bit_cnt<=0; sda_out<=1;stretch_scl<=0;
            end else if(stop_det)begin
                state<= IDLE; sda_out<=1; stretch_scl<=0;
            end else begin
                case(state)
                    IDLE:begin
                        bit_cnt<= 0; sda_out<= 1; stretch_scl<=0;
                    end
                    RX_ADDR:begin
                        sda_out<= 1;
                        if(scl_rise)begin
                            shift_reg<= {shift_reg[6:0], sda_inout};
                            bit_cnt<= bit_cnt+1;
                         end
                         if(scl_fall && bit_cnt == 4'd8) state<= ACK_ADDR;
                    end
                    ACK_ADDR:begin
                        bit_cnt<= 0;
                        if(shift_reg[7:1] == VIRTUAL_ADDR)begin
                            sda_out<= 0; //this is ACK
                            rw_bit_out <= shift_reg[0];
                            if(scl_fall)state<= shift_reg[0] ? WAIT_FETCH : RX_PAYLOAD;
                        end else begin
                            sda_out<= 1; //this is NACK
                            if(scl_fall)state<= IDLE;
                         end
                     end
                     RX_PAYLOAD:begin
                        sda_out<=1;
                        if(scl_rise)begin
                            shift_reg<= {shift_reg[6:0], sda_inout};
                            bit_cnt<= bit_cnt+1;
                        end
                        if(scl_fall && bit_cnt == 4'd8)state<= ACK_PAYLOAD;
                      end
                      ACK_PAYLOAD:begin
                        bit_cnt<=0;sda_out<=0; //ACK
                        if(scl_fall)begin
                            rx_data <= shift_reg;
                            rx_valid <= 1;
                            state<= WAIT_FETCH;
                        end
                      end
                      WAIT_FETCH:begin
                        stretch_scl<=1;
                        if(master_tx_done)begin
                            shift_reg<= tx_data_in;
                            state<= rw_bit_out ? TX_PAYLOAD : RX_PAYLOAD;
                        end
                      end
                      TX_PAYLOAD:begin
                        stretch_scl<=0; 
                        if(scl_fall)begin
                            sda_out<= shift_reg[7 - bit_cnt];
                            bit_cnt<= bit_cnt+1;
                        end
                        if(scl_fall && bit_cnt == 4'd8) state<= IDLE;
                      end
                      endcase
                      end
                      end
                      end 
            
endmodule
