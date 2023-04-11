`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/04/2023 03:32:20 PM
// Design Name: 
// Module Name: mcp4728
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
// Module ignore ACK signals from device mcp4728. Only Read Device Address and write DAC values to corresponding DAC according LDAC.   
//////////////////////////////////////////////////////////////////////////////////



module mcp4728 (
    input         clk,        // clock is need to be 200khz or lower (SCL max 50KHZ)
    input         rst,        // reset
    output        scl,        // SCL out
    inout         sda,        // SDA Out
    input  [11:0] dac0,       // dac0 0..4095
    input  [11:0] dac1,       // dac1 0..4095
    input  [11:0] dac2,       // dac2 0..4095
    input  [11:0] dac3,       // dac3 0..4095
    input  [ 2:0] dacNumber,  // number of DAC according of LDAC Line
    output [ 3:0] ldac,       // LDAC output PINs of corresponding mcp4728 

    input needTransmit,       //  if this is 1, the circle is started to transmit values in circuit. Push to 0 to stop update. 

    // only for debug
    output [7:0] readAddress,
    output [4:0] transmitState,
    output sda_debug,
    output [7:0] sendReceiveCounter_debug
);



  reg [31:0] readReq;
  reg [ 4:0] state;
  reg [ 7:0] sendReceiveCounter;
  assign sendReceiveCounter_debug = sendReceiveCounter;
  reg [7:0] addressReceive;
  reg transmitClockEnable;
  reg [3:0] ldacReg;

  reg sda_reg;
  assign readAddress = addressReceive;
  reg transmit;
  assign transmitState = state;
  assign sda = transmit ? sda_reg : 'bz;
  reg [1:0] clkHalf;
  reg clkAdd;
  assign scl = transmitClockEnable ? clkHalf[1] : 1;
  assign ldac = ldacReg;
  assign sda_debug = sda_reg;


  always @(posedge clk)
    if (rst) begin
      state <= 0;
      transmitClockEnable <= 0;
      ldacReg[3:0] <= 4'b1111;
      transmit <= 0;
      addressReceive <= 0;
    end else begin
      // read 1 address 
      case (state)

        0: begin

          // page 33 of http://ww1.microchip.com/downloads/en/devicedoc/22187e.pdf
          // Read Address for device for future write DAC values in fast mode
          readReq <= 29'b000000000z00001100z111000001z;
          addressReceive <= 0;

          sendReceiveCounter <= 0;
          ldacReg[3:0] <= 4'b1111;
          transmitClockEnable <= 0;
          transmit <= 1;
          sda_reg <= 1;
          clkHalf <= 0;
          if (needTransmit) begin
            state <= 1;
          end
        end

        1: begin
          clkHalf <= clkHalf + 1;

          if (clkHalf == 0) begin
            sda_reg <= readReq[28-sendReceiveCounter];
            sendReceiveCounter <= sendReceiveCounter + 1;
            transmit <= 1;
            if (sendReceiveCounter == 18) begin
              ldacReg[dacNumber] <= 0;
            end

            if (sendReceiveCounter == 28) begin
              ldacReg[3:0] <= 4'b1111;
              transmit <= 0;
              state <= 2;
              sendReceiveCounter <= 0;
            end
          end
          if (clkHalf == 2) begin
            if (sendReceiveCounter == 20) begin
              sda_reg <= 0;
            end
            transmitClockEnable <= 1;
          end
        end
        2: begin
          clkHalf <= clkHalf + 1;
          if (clkHalf == 0) begin
            state <= 3;
          end
        end
        3: begin
          clkHalf <= clkHalf + 1;
          if (clkHalf == 2) begin
            addressReceive[7-sendReceiveCounter] <= sda;
            sda_reg <= sda;
            if (sendReceiveCounter != 7) begin
              sendReceiveCounter <= sendReceiveCounter + 1;
            end
          end
          if (clkHalf == 0) begin
            if (sendReceiveCounter == 7) begin
              state <= 4;
              transmit <= 1;
              sda_reg <= 0;
              sendReceiveCounter <= 0;

            end

          end

        end
        4: begin

          clkHalf <= clkHalf + 1;
          if (clkHalf == 0) begin

            if (sendReceiveCounter == 1) begin

              ldacReg[3:0] <= 4'b1111;

            end else begin
              sendReceiveCounter <= sendReceiveCounter + 1;
            end
          end
          if (clkHalf == 2) begin

            if (sendReceiveCounter == 1) begin
              transmitClockEnable <= 0;
              sda_reg <= 1;


              state <= 5;  //
              transmit <= 1;
              sendReceiveCounter <= 0;

            end
          end
        end


        5: begin


          readReq[9] <= 0;
          readReq[8] <= 1;
          readReq[7] <= 1;
          readReq[6] <= 0;
          readReq[5] <= 0;
          readReq[4] <= addressReceive[7];
          readReq[3] <= addressReceive[6];
          readReq[2] <= addressReceive[5];
          readReq[1] <= 0;
          readReq[0] <= 'bz;
          // delay
          if (sendReceiveCounter != 3) begin
            sendReceiveCounter <= sendReceiveCounter + 1;

          end else begin
            state <= 6;
            sendReceiveCounter <= 0;
          end


          ldacReg[dacNumber] <= 0;
          transmit <= 1;
          sda_reg <= 1;
          clkHalf <= 0;
          transmitClockEnable <= 0;
        end
        6: begin

          // DAC0


          clkHalf <= clkHalf + 1;

          if (clkHalf == 3) begin
            transmitClockEnable = 1;
          end

          if (clkHalf == 0) begin



            transmit <= 1;  //readReq[9-sendReceiveCounter]==1'bz ? 0 : 1;


            sda_reg  <= readReq[9-sendReceiveCounter];
            if (sendReceiveCounter == 9) begin

              readReq[17:14] <= 0;
              readReq[13:10] <= dac0[11:8];
              readReq[9] <= 1'bz;
              readReq[8:1] <= dac0[7:0];
              readReq[0] <= 1'bz;
              sendReceiveCounter <= 0;
              state <= 7;

            end else begin
              sendReceiveCounter <= sendReceiveCounter + 1;
            end
          end

        end
        7: begin

          clkHalf <= clkHalf + 1;
          if (clkHalf == 0) begin
            sda_reg  <= readReq[17-sendReceiveCounter];

            transmit <= 1;  

            if (sendReceiveCounter == 17) begin
              readReq[17:14] <= 0;
              readReq[13:10] <= dac1[11:8];
              readReq[9] <= 1'bz;
              readReq[8:1] <= dac1[7:0];
              readReq[0] <= 1'bz;
              sendReceiveCounter <= 0;
              state <= 8;
            end else begin
              sendReceiveCounter <= sendReceiveCounter + 1;
            end
          end


        end
        8: begin

          clkHalf <= clkHalf + 1;
          if (clkHalf == 0) begin
            sda_reg  <= readReq[17-sendReceiveCounter];

            transmit <= 1;  

            if (sendReceiveCounter == 17) begin
              readReq[17:14] <= 0;
              readReq[13:10] <= dac2[11:8];
              readReq[9] <= 1'bz;
              readReq[8:1] <= dac2[7:0];
              readReq[0] <= 1'bz;
              sendReceiveCounter <= 0;
              state <= 9;
            end else begin
              sendReceiveCounter <= sendReceiveCounter + 1;
            end
          end
        end
        9: begin

          clkHalf <= clkHalf + 1;
          if (clkHalf == 0) begin
            sda_reg  <= readReq[17-sendReceiveCounter];

            transmit <= 1; 

            if (sendReceiveCounter == 17) begin
              readReq[17:14] <= 0;
              readReq[13:10] <= dac3[11:8];
              readReq[9] <= 1'bz;
              readReq[8:1] <= dac3[7:0];
              readReq[0] <= 1'bz;
              sendReceiveCounter <= 0;
              state <= 10;
            end else begin
              sendReceiveCounter <= sendReceiveCounter + 1;
            end
          end
        end

        10: begin

          clkHalf <= clkHalf + 1;
          if (clkHalf == 0) begin
            sda_reg  <= readReq[17-sendReceiveCounter];

            transmit <= 1;

            if (sendReceiveCounter == 17) begin
              state <= 11;
              sendReceiveCounter <= 0;
            end else begin
              sendReceiveCounter <= sendReceiveCounter + 1;
            end
          end
        end

        11: begin

          clkHalf <= clkHalf + 1;
          if (clkHalf == 0) begin




            if (sendReceiveCounter == 3) begin
              ldacReg[3:0] <= 4'b1111;
              sda_reg <= 1;

              state <= 0;  
              transmit <= 1;

            end else begin

              sendReceiveCounter <= sendReceiveCounter + 1;
              if (sendReceiveCounter == 0) begin
                sda_reg <= 0;
              end else begin
                sda_reg <= 1;
              end

            end
          end
          if (clkHalf == 2) begin
            if (sendReceiveCounter == 1) begin
              transmitClockEnable = 0;
            end
          end

        end

      endcase
    end







endmodule
