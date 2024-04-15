`timescale 1ns / 1ps
`include "interfaces.vh"

// ZCU111 top module for messing around with the RFDC.
module zcu111_top(
        // analog input for SysMon
        input VP,               // doesn't need a pin loc
        input VN,               // doesn't need a pin loc
        // RFDC inputs
        input ADC0_CLK_P,       // AF5 (300 MHz)(or maybe 600 as specified in IP?) Yes, 600.
        input ADC0_CLK_N,       // AF4 (300 MHz)(or maybe 600 as specified in IP?)
        input ADC0_VIN_P,       // AP2
        input ADC0_VIN_N,       // AP1
        input ADC1_VIN_P,       // AM2
        input ADC1_VIN_N,       // AM1
        
        input ADC2_CLK_P,       // AD5
        input ADC2_CLK_N,       // AD4
        input ADC2_VIN_P,       // AK2
        input ADC2_VIN_N,       // AK1
        input ADC3_VIN_P,       // AH2
        input ADC3_VIN_N,       // AH1
        
        input ADC4_CLK_P,       // AB5
        input ADC4_CLK_N,       // AB4
        input ADC4_VIN_P,       // AF2
        input ADC4_VIN_N,       // AF1
        input ADC5_VIN_P,       // AD2
        input ADC5_VIN_N,       // AD1
        
        input ADC6_CLK_P,       // Y5
        input ADC6_CLK_N,       // Y4
        input ADC6_VIN_P,       // AB2
        input ADC6_VIN_N,       // AB1
        input ADC7_VIN_P,       // Y2
        input ADC7_VIN_N,       // Y1        

        input DAC4_CLK_P,       // N5
        input DAC4_CLK_N,       // N4
        // output DAC4_VOUT_P,     // J2
        // output DAC4_VOUT_N,     // J1
        // output DAC5_VOUT_P,     // G2
        // output DAC5_VOUT_N,     // G1
        output DAC6_VOUT_P,     // E2
        output DAC6_VOUT_N,     // E1
        output DAC7_VOUT_P,     // C2
        output DAC7_VOUT_N,     // C1

        input SYSREF_P,         // U5
        input SYSREF_N,         // U4
        // PL clock to capture SYSREF in PL (24 MHz)
        input FPGA_REFCLK_IN_P, //  AL16
        input FPGA_REFCLK_IN_N, //  AL15
        // PL sysref input (1.5 MHz)
        input SYSREF_FPGA_P,    // AK17
        input SYSREF_FPGA_N,    // AK16
        output [1:0] PL_USER_LED        // { AP13, AR13 }
    );

    parameter	     THIS_DESIGN = "LPF";
   
    
    (* KEEP = "TRUE"  *)
    wire ps_clk;
    wire ps_reset;
    
    // ADC AXI4-Stream clock.
    wire aclk;
    // divided by 2
    wire aclk_div2;
    wire aresetn = 1'b1;
    // ADC AXI4-Streams
    // These macros are definied in verilog-library-barawn/include/interfaces.vh.
    // They definie the tdata, tvalid, and tready wires in a compact way.
    `DEFINE_AXI4S_MIN_IF( adc0_ , 128 );
    `DEFINE_AXI4S_MIN_IF( adc1_ , 128 );
    `DEFINE_AXI4S_MIN_IF( adc2_ , 128 );
    `DEFINE_AXI4S_MIN_IF( adc3_ , 128 );
    `DEFINE_AXI4S_MIN_IF( adc4_ , 128 );
    `DEFINE_AXI4S_MIN_IF( adc5_ , 128 );
    `DEFINE_AXI4S_MIN_IF( adc6_ , 128 );
    `DEFINE_AXI4S_MIN_IF( adc7_ , 128 );
    // LPF AXI4 Stream
    `DEFINE_AXI4S_MIN_IF( lpf0_ , 128 );
    wire lpf0copy_tready; // for ADC captures
    wire lpf0copy_tvalid;
    `DEFINE_AXI4S_MIN_IF( lpf1_ , 128 );
    wire lpf1copy_tready; // for ADC captures
    wire lpf1copy_tvalid;
    // `DEFINE_AXI4S_MIN_IF( lpf2_ , 128 );
    // `DEFINE_AXI4S_MIN_IF( lpf3_ , 128 );
    // `DEFINE_AXI4S_MIN_IF( lpf4_ , 128 );
    // `DEFINE_AXI4S_MIN_IF( lpf5_ , 128 );
    // `DEFINE_AXI4S_MIN_IF( lpf6_ , 128 );
    // `DEFINE_AXI4S_MIN_IF( lpf7_ , 128 );
    // DAC AXI4 Stream
    `DEFINE_AXI4S_MIN_IF( dac6_ , 256 );
    `DEFINE_AXI4S_MIN_IF( dac7_ , 256 );
    // `DEFINE_AXI4S_MIN_IF( dac4_ , 256 );
    // `DEFINE_AXI4S_MIN_IF( dac5_ , 256 );

    
    // SYSREF capture register
    (* IOB = "TRUE" *)
    reg sysref_reg_slowclk = 0;
    reg sysref_reg = 0;
    // output clock (187.5 MHz, unused)
    wire adc_clk;

    // Generate clocks
    // Input clock is the 24 MHz FPGA reference clock
    // ref_clk is 75 MHz
    // aclk is 375 MHz (for AXI-Stream)
    // aclk_div2 is 187.5 MHz (half freq of aclk)
    slow_refclk_wiz u_rcwiz(.reset(refclkwiz_reset),
                            .clk_in1_p(FPGA_REFCLK_IN_P),
                            .clk_in1_n(FPGA_REFCLK_IN_N),
                            .clk_out1(ref_clk),
                            .clk_out2(aclk),
                            .clk_out3(aclk_div2),
                            .locked(refclkwiz_locked));
    
    // input sysref
    wire sys_ref;
    IBUFDS u_srbuf(.I(SYSREF_FPGA_P),.IB(SYSREF_FPGA_N),.O(sys_ref));    
    
    always @(posedge ref_clk) sysref_reg_slowclk <= sys_ref;
    always @(posedge aclk) sysref_reg <= sysref_reg_slowclk;
    
    genvar i;
    generate
         if (THIS_DESIGN == "LPF") begin : LPF

            ///////////////////////////////////////////////////////////////////////////////////////////
            // Channel 0: uses the custom Low Pass Filter implementation from verilog-library-barawn //
            ///////////////////////////////////////////////////////////////////////////////////////////

            wire [95:0] lpf0_compressed;
            wire [95:0] adc0_compressed;    
            // CHANNEL 0 MSB aligned
            for(i=0; i<8; i=i+1)
                begin: bitRepack0 // Align data for use with the shannon_whitaker_lpfull_v2 12-bit input
                    assign lpf0_compressed[i*12+11:i*12] = lpf0_tdata[i*16+15:i*16+4]; // Slice out most significant 12 out of 16.
                end

            for(i=0; i<8; i=i+1)
                begin: bitUnpack0 // Receive the 12 bits from the LPF, and re-align to the 12 most significant of 16 for use elsewhere
                    assign adc0_tdata[i*16+15:i*16] =  {{adc0_compressed[i*12+11:i*12]}, {4{1'b0}}}; // MSB aligned
                end

            // Not using AXI4s, so just force these open
            assign lpf0copy_tready = 1'b1;
            assign adc0_tvalid = 1'b1;

            shannon_whitaker_lpfull_v2 fir_0 (
                .clk_i(aclk),
                .in_i(lpf0_compressed),
                .out_o(adc0_compressed)
                );

            /////////////////////////////////////////////////////////////////////////
            // Channel 1: uses the IP generated FIR Low Pass Filter implementation //
            /////////////////////////////////////////////////////////////////////////

            wire [127:0] lpf1_compressed;
            wire [127:0] adc1_compressed;
            // CHANNEL 1 LSB aligned
            for(i=0; i<8; i=i+1)
                begin: bitRepack1 // for input to filter
                    assign lpf1_compressed[i*16+11:i*16] = {{4{1'b0}}, {lpf1_tdata[i*16+15:i*16+4]}}; // Slice out most significant 12 out of 16, and align to least
                end

            for(i=0; i<8; i=i+1)
                begin: bitUnpack1 // for output from filter
                    assign adc1_tdata[i*16+15:i*16] =  {{adc1_compressed[i*16+11:i*16]}, {4{1'b0}}}; // LSB aligned
                    // reverse the word order (again)
                    // assign adc1_tdata[(7-i)*16+15:(7-i)*16] =  {{adc1_compressed[i*16+11:i*16]}, {4{1'b0}}}; // LSB aligned
                end

            // // Force tvalid here since it's driven elsewhere (namely the ADC captures)
            assign lpf1copy_tvalid = 1'b1;
            fir_compiler_lpf fir_1 ( // This is 12 bits wide, but data is taken in chunks of 16 LSB aligned
                .aclk(aclk),         
                .s_axis_data_tvalid(lpf1copy_tvalid),
                .s_axis_data_tready(lpf1copy_tready),  
                .s_axis_data_tdata(lpf1_compressed),
                .m_axis_data_tvalid(adc1_tvalid),  
                .m_axis_data_tdata(adc1_compressed),
                .m_axis_data_tready(adc1_tready)
                );

            // These two dac_xfer_x2 modules connect:
            // RF Data Converter ADC AXI4 stream ->
            // dac_xfer module, which stacks two 128 data into one 256 ->
            // RF Data Converter DAC AXI4 stream
            dac_xfer_x2 u_dac12_xfer( .aclk(aclk),
                                      .aresetn(1'b1),
                                      .aclk_div2(aclk_div2),
                                      `CONNECT_AXI4S_MIN_IF( s_axis_ , adc0_ ),// CHANGED FROM 0 1 2 3
                                      `CONNECT_AXI4S_MIN_IF( m_axis_ , dac6_ )); 
            dac_xfer_x2 u_dac13_xfer( .aclk(aclk),
                                      .aresetn(1'b1),
                                      .aclk_div2(aclk_div2),
                                      `CONNECT_AXI4S_MIN_IF( s_axis_ , adc1_ ),
                                      `CONNECT_AXI4S_MIN_IF( m_axis_ , dac7_ ));
            // dac_xfer_x2 u_dac10_xfer( .aclk(aclk),
            //                           .aresetn(1'b1),
            //                           .aclk_div2(aclk_div2),
            //                           `CONNECT_AXI4S_MIN_IF( s_axis_ , adc2_ ),
            //                           `CONNECT_AXI4S_MIN_IF( m_axis_ , dac4_ ));
            // dac_xfer_x2 u_dac11_xfer( .aclk(aclk),
            //                           .aresetn(1'b1),
            //                           .aclk_div2(aclk_div2),
            //                           `CONNECT_AXI4S_MIN_IF( s_axis_ , adc3_ ),
            //                           `CONNECT_AXI4S_MIN_IF( m_axis_ , dac5_ ));

                        

            // This is the block diagram's (zcu111_mts's) wrapper.
            // The RF Data Converter IP is inside it, and is communicated with over AXI4 Stream interfaces                     
            zcu111_mts_wrapper u_ps( .Vp_Vn_0_v_p( VP ),
                                         .Vp_Vn_0_v_n( VN ),
                                         // sysref
                                         .sysref_in_0_diff_p( SYSREF_P ),
                                         .sysref_in_0_diff_n( SYSREF_N ),
                                         // clocks
                                         .adc0_clk_0_clk_p( ADC0_CLK_P ),
                                         .adc0_clk_0_clk_n( ADC0_CLK_N ),
                                         .adc1_clk_0_clk_p( ADC2_CLK_P ),
                                         .adc1_clk_0_clk_n( ADC2_CLK_N ),
                                         .adc2_clk_0_clk_p( ADC4_CLK_P ),
                                         .adc2_clk_0_clk_n( ADC4_CLK_N ),
                                         .adc3_clk_0_clk_p( ADC6_CLK_P ),
                                         .adc3_clk_0_clk_n( ADC6_CLK_N ),
                                         // vins
                                         .vin0_01_0_v_p( ADC0_VIN_P ),
                                         .vin0_01_0_v_n( ADC0_VIN_N ),
                                         .vin0_23_0_v_p( ADC1_VIN_P ),
                                         .vin0_23_0_v_n( ADC1_VIN_N ),
                                         .vin1_01_0_v_p( ADC2_VIN_P ),
                                         .vin1_01_0_v_n( ADC2_VIN_N ),
                                         .vin1_23_0_v_p( ADC3_VIN_P ),
                                         .vin1_23_0_v_n( ADC3_VIN_N ),
                                         .vin2_01_0_v_p( ADC4_VIN_P ),
                                         .vin2_01_0_v_n( ADC4_VIN_N ),
                                         .vin2_23_0_v_p( ADC5_VIN_P ),
                                         .vin2_23_0_v_n( ADC5_VIN_N ),
                                         .vin3_01_0_v_p( ADC6_VIN_P ),
                                         .vin3_01_0_v_n( ADC6_VIN_N ),
                                         .vin3_23_0_v_p( ADC7_VIN_P ),
                                         .vin3_23_0_v_n( ADC7_VIN_N ),

                                         // These are the ADC values
                                         `CONNECT_AXI4S_MIN_IF( m00_axis_0_ , lpf0_ ), // These two will connect to LPFs
                                         `CONNECT_AXI4S_MIN_IF( m02_axis_0_ , lpf1_ ), // After the LPFs they will go to adc0_ and adc1_
                                         `CONNECT_AXI4S_MIN_IF( m10_axis_0_ , adc2_ ),
                                         `CONNECT_AXI4S_MIN_IF( m12_axis_0_ , adc3_ ),
                                         `CONNECT_AXI4S_MIN_IF( m20_axis_0_ , adc4_ ),
                                         `CONNECT_AXI4S_MIN_IF( m22_axis_0_ , adc5_ ),
                                         `CONNECT_AXI4S_MIN_IF( m30_axis_0_ , adc6_ ),
                                         `CONNECT_AXI4S_MIN_IF( m32_axis_0_ , adc7_ ),
                                         // resets and clocks
                                         .s_axi_aclk_0( aclk_div2 ), // Used for DACs  
                                         .s_axi_aresetn_0( 1'b1 ),
                                         .s_axis_aclk_0( aclk ), // Used for ADCs
                                         .s_axis_aresetn_0( 1'b1 ),

                                         // feed back to inputs for the ADC Captures
                                         `CONNECT_AXI4S_MIN_IF( S_AXIS_0_ , lpf0_ ),
                                         `CONNECT_AXI4S_MIN_IF( S_AXIS_1_ , adc0_ ),
                                         `CONNECT_AXI4S_MIN_IF( S_AXIS_2_ , lpf1_ ),
                                         `CONNECT_AXI4S_MIN_IF( S_AXIS_3_ , adc1_ ),
                                         
                                         .dac1_clk_0_clk_p(DAC4_CLK_P),
                                         .dac1_clk_0_clk_n(DAC4_CLK_N),
                                         
                                         // Swapping these for testing does nothing
                                         // This is because they are hardwired
                                        //  .vout10_0_v_p(DAC4_VOUT_P),
                                        //  .vout10_0_v_n(DAC4_VOUT_N),
                                        //  .vout11_0_v_p(DAC5_VOUT_P),
                                        //  .vout11_0_v_n(DAC5_VOUT_N),
                                         .vout12_0_v_p(DAC6_VOUT_P),
                                         .vout12_0_v_n(DAC6_VOUT_N),
                                         .vout13_0_v_p(DAC7_VOUT_P),
                                         .vout13_0_v_n(DAC7_VOUT_N),
                                         
                                         // Drive the DACs
                                        //  `CONNECT_AXI4S_MIN_IF( s10_axis_0_ , dac4_ ),
                                        //  `CONNECT_AXI4S_MIN_IF( s11_axis_0_ , dac5_ ),
                                         `CONNECT_AXI4S_MIN_IF( s12_axis_0_ , dac6_ ),
                                         `CONNECT_AXI4S_MIN_IF( s13_axis_0_ , dac7_ ),

                                         .pl_clk0( ps_clk ),
                                         .pl_resetn0( ps_reset ),
                                         .clk_adc0_0(adc_clk),

                                         .user_sysref_adc_0(sysref_reg));
         end                     
    endgenerate        
endmodule