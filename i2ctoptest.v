`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/08/2023 10:13:36 AM
// Design Name: 
// Module Name: i2ctoptest
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//  Verilog I2C module for write DAC values in FAST mode for 4 DAC mcp4728  
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



module i2ctoptest (

    input CLK100MHZ,
    output mcp4728_dac_scl,
    inout mcp4728_dac_sda,
    output [3:0] mcp4728_ldac
);

  reg reset;
  reg [31:0] resetcounter;

  reg [11:0] mcp4728_dac0;
  reg [11:0] mcp4728_dac1;
  reg [11:0] mcp4728_dac2;
  reg [11:0] mcp4728_dac3;

  // 
  reg mcp4728_needTransmit;



  wire clock200khz;
  assign clock200khz = clock200khz_gen[8];
  reg [8:0] clock200khz_gen;

  reg [2:0] mcp4728_dac_number;
  wire [7:0] mcp4728_readAddressValue;
  wire [4:0] mcp4728_transmitState;

  // only for debug
  wire sda_debug;
  wire [7:0] sendReceiveCounter_debug;
  wire sda_read_debug;
  mcp4728 mcp4728_dacread (
      .clk(clock200khz),  // clock is need to be 200khz or lower (SCL max 50KHZ)
      .rst(reset),  // reset
      .scl(mcp4728_dac_scl),  // SCL out
      .sda(mcp4728_dac_sda),  // SDA Out
      .dac0(mcp4728_dac0),  // dac0 0..4095
      .dac1(mcp4728_dac1),  // dac1 0..4095
      .dac2(mcp4728_dac2),  // dac2 0..4095
      .dac3(mcp4728_dac3),  // dac3 0..4095
      .dacNumber(mcp4728_dac_number),  // number of DAC according of LDAC Line
      .ldac(mcp4728_ldac),  // LDAC output PIN        
      .needTransmit(mcp4728_needTransmit), // if this is 1, the circle is started to transmit values in circuit. Push to 0 to stop update.         

      // debug signals:
      .transmitState(mcp4728_transmitState),  // state   
      .readAddress(mcp4728_readAddressValue),  // read address for debug
      .sda_debug(sda_debug),
      .sendReceiveCounter_debug(sendReceiveCounter_debug)
  );

  wire clockila;
  reg [2:0] clockilagen;
  assign clockila = clockilagen[2];

  // TESTS For ILA  debug
  ila_0 ilatest (
      .clk(clockila),
      .probe0(mcp4728_readAddressValue),
      .probe1(mcp4728_transmitState),
      .probe2(mcp4728_dac_scl),
      .probe3(sda_debug),
      .probe4(mcp4728_ldac),
      .probe5(mcp4728_dac_number),
      .probe6(clock200khz),
      .probe7(sendReceiveCounter_debug)
  );


  always @(posedge CLK100MHZ) begin

    // check DAC number 2
    mcp4728_dac_number <= 2;
    
    clockilagen <= clockilagen + 1;
    clock200khz_gen <= clock200khz_gen + 1;


    mcp4728_dac0 <= 512;
    mcp4728_dac1 <= 1024;
    mcp4728_dac2 <= 2048;
    mcp4728_dac3 <= 4095;

    // reset
    if (resetcounter == 10000000) reset <= 0;
    else begin
      resetcounter <= resetcounter + 1;
      reset <= 1;
    end

    if (reset == 0) begin

      mcp4728_needTransmit <= 1;
    end else begin
      mcp4728_needTransmit <= 0;
    end

  end




endmodule
