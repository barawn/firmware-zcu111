`timescale 1ns / 1ps
`include "interfaces.vh"

module lpf_tb;

    wire clk;
    tb_rclk #(.PERIOD(5.0)) u_clk(.clk(clk));
    reg [11:0] samples[7:0];
    integer i;
    initial for (i=0;i<8;i=i+1) samples[i] <= 0;
    wire [12*8-1:0] sample_arr =
        { samples[7],
          samples[6],
          samples[5],
          samples[4],
          samples[3],
          samples[2],
          samples[1],
          samples[0] };

    wire [11:0] outsample[7:0];
    wire [11:0] outsampleB[7:0];
    wire [12*8-1:0] outsample_arr;
    wire [12*8-1:0] outsampleB_arr;

    wire [16*8-1:0] lpf1_compressed;
    wire [16*8-1:0] adc1_compressed;  

    `DEFINE_AXI4S_MIN_IF( lpf1_ , 128 );
    `DEFINE_AXI4S_MIN_IF( adc1_ , 128 );
    
    reg [11:0] pretty_insample = {12{1'b0}};    
    reg [11:0] pretty_sample = {12{1'b0}};
    integer pi;
    always @(posedge clk) begin
        #0.05;
        pretty_sample <= outsample[0];
        pretty_insample <= samples[0];
        for (pi=1;pi<8;pi=pi+1) begin
            #(5.0/8);
            pretty_sample <= outsample[pi];
            pretty_insample <= samples[pi];
        end            
    end
    generate
        genvar j;
        for (j=0;j<8;j=j+1) begin : DEVEC
            assign outsample[j] = outsample_arr[12*j +: 12];
            assign outsampleB[j] = outsampleB_arr[12*j +: 12];
        end
    endgenerate

    genvar idx;
    generate
    for(idx=0; idx<8; idx=idx+1)
        begin: bitRepack1
            assign lpf1_compressed[idx*16+15:idx*16] = {{4{1'b0}}, {sample_arr[idx*12+11:idx*12]}}; // Slice out 12 and align to least out of 16
        end

    for(idx=0; idx<8; idx=idx+1)
        begin: bitUnpack1
            assign outsampleB_arr[idx*12+11:idx*12] =  adc1_compressed[idx*16+12:idx*16+1]; // LSB aligned, reset to 13 per advice from PSA
        end
    endgenerate

            
    shannon_whitaker_lpfull_v2 uut(.clk_i(clk),
                                .in_i(sample_arr),
                                .out_o(outsample_arr));
    // // Not using AXI4s, so just force these open
    assign lpf1_tvalid = 1'b1;
    assign adc1_tready = 1'b1;
     fir_for_sim uut2 ( // This is 12 bits wide
                .aclk(clk),         
                .s_axis_data_tvalid(lpf1_tvalid),
                .s_axis_data_tready(lpf1_tready),  
                .s_axis_data_tdata(lpf1_compressed),
                .m_axis_data_tvalid(adc1_tvalid),  
                .m_axis_data_tdata(adc1_compressed)
                // .m_axis_data_tready(adc1_tready)
                // `CONNECT_AXI4S_MIN_IF( s_axis_data_ , lpf1_ ),
                // `CONNECT_AXI4S_MIN_IF( m_axis_data_ , adc1_ )
                );

    integer k,f, sample_idx;
    initial begin
        for(sample_idx=0; sample_idx<8; sample_idx = sample_idx+1) begin
            f = $fopen($sformatf("simulation_output_in_%1d.txt", sample_idx), "w");
            for(k=0; k<500; k = k+1) begin
                @(posedge clk);
                // Writing very explicitly
                $fwrite(f, "%b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b\n",
                            sample_arr[1*12-1 -:12],
                            sample_arr[2*12-1 -:12],
                            sample_arr[3*12-1 -:12],
                            sample_arr[4*12-1 -:12],
                            sample_arr[5*12-1 -:12],
                            sample_arr[6*12-1 -:12],
                            sample_arr[7*12-1 -:12],
                            sample_arr[8*12-1 -:12],

                            outsample_arr[1*12-1 -:12],
                            outsample_arr[2*12-1 -:12],
                            outsample_arr[3*12-1 -:12],
                            outsample_arr[4*12-1 -:12],
                            outsample_arr[5*12-1 -:12],
                            outsample_arr[6*12-1 -:12],
                            outsample_arr[7*12-1 -:12],
                            outsample_arr[8*12-1 -:12],

                            outsampleB_arr[1*12-1 -:12],
                            outsampleB_arr[2*12-1 -:12],
                            outsampleB_arr[3*12-1 -:12],
                            outsampleB_arr[4*12-1 -:12],
                            outsampleB_arr[5*12-1 -:12],
                            outsampleB_arr[6*12-1 -:12],
                            outsampleB_arr[7*12-1 -:12],
                            outsampleB_arr[8*12-1 -:12]  );
                // if(k>2 && k<10) begin
                //     samples[0] = 1000;
                //     samples[1] = 1000;
                // end else begin
                //     samples[0] = 0;
                //     samples[1] = 0;
                // end
                if(k==100) begin
                    samples[sample_idx] = 12'b001111101000;//1,000
                // end else if(k==101) begin
                //     samples[0] = 0   ;
                //     samples[1] = 1000;
                end else begin
                    samples[sample_idx] = 0;
                end
                #0.01;
            end
            $fclose(f);
            #0.01;


            f = $fopen($sformatf("simulation_output_negative_in_%1d.txt", sample_idx), "w");
            for(k=0; k<500; k = k+1) begin
                @(posedge clk);
                // Writing very explicitly
                $fwrite(f, "%b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b\n",
                            sample_arr[1*12-1 -:12],
                            sample_arr[2*12-1 -:12],
                            sample_arr[3*12-1 -:12],
                            sample_arr[4*12-1 -:12],
                            sample_arr[5*12-1 -:12],
                            sample_arr[6*12-1 -:12],
                            sample_arr[7*12-1 -:12],
                            sample_arr[8*12-1 -:12],

                            outsample_arr[1*12-1 -:12],
                            outsample_arr[2*12-1 -:12],
                            outsample_arr[3*12-1 -:12],
                            outsample_arr[4*12-1 -:12],
                            outsample_arr[5*12-1 -:12],
                            outsample_arr[6*12-1 -:12],
                            outsample_arr[7*12-1 -:12],
                            outsample_arr[8*12-1 -:12],

                            outsampleB_arr[1*12-1 -:12],
                            outsampleB_arr[2*12-1 -:12],
                            outsampleB_arr[3*12-1 -:12],
                            outsampleB_arr[4*12-1 -:12],
                            outsampleB_arr[5*12-1 -:12],
                            outsampleB_arr[6*12-1 -:12],
                            outsampleB_arr[7*12-1 -:12],
                            outsampleB_arr[8*12-1 -:12]  );
                // if(k>2 && k<10) begin
                //     samples[0] = 1000;
                //     samples[1] = 1000;
                // end else begin
                //     samples[0] = 0;
                //     samples[1] = 0;
                // end
                if(k==100) begin
                    samples[sample_idx] = 12'b110000011000;//-1,000
                    //                    
                // end else if(k==101) begin
                //     samples[0] = 0   ;
                //     samples[1] = 1000;
                end else begin
                    samples[sample_idx] = 0;
                end
                #0.01;
            end
 
            $fclose(f);
            #0.01;

            if(sample_idx <7) begin
                f = $fopen($sformatf("simulation_output_double_in_%1d.txt", sample_idx), "w");
                for(k=0; k<500; k = k+1) begin
                    @(posedge clk);
                    // Writing very explicitly
                    $fwrite(f, "%b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b\n",
                                sample_arr[1*12-1 -:12],
                                sample_arr[2*12-1 -:12],
                                sample_arr[3*12-1 -:12],
                                sample_arr[4*12-1 -:12],
                                sample_arr[5*12-1 -:12],
                                sample_arr[6*12-1 -:12],
                                sample_arr[7*12-1 -:12],
                                sample_arr[8*12-1 -:12],

                                outsample_arr[1*12-1 -:12],
                                outsample_arr[2*12-1 -:12],
                                outsample_arr[3*12-1 -:12],
                                outsample_arr[4*12-1 -:12],
                                outsample_arr[5*12-1 -:12],
                                outsample_arr[6*12-1 -:12],
                                outsample_arr[7*12-1 -:12],
                                outsample_arr[8*12-1 -:12],

                                outsampleB_arr[1*12-1 -:12],
                                outsampleB_arr[2*12-1 -:12],
                                outsampleB_arr[3*12-1 -:12],
                                outsampleB_arr[4*12-1 -:12],
                                outsampleB_arr[5*12-1 -:12],
                                outsampleB_arr[6*12-1 -:12],
                                outsampleB_arr[7*12-1 -:12],
                                outsampleB_arr[8*12-1 -:12]  );
                    // if(k>2 && k<10) begin
                    //     samples[0] = 1000;
                    //     samples[1] = 1000;
                    // end else begin
                    //     samples[0] = 0;
                    //     samples[1] = 0;
                    // end
                    if(k==100) begin
                        samples[sample_idx] = 12'b001111101000;//-1,000
                        samples[sample_idx+1] = 12'b001111101000;//-1,000
                        //                    
                    // end else if(k==101) begin
                    //     samples[0] = 0   ;
                    //     samples[1] = 1000;
                    end else begin
                        samples[sample_idx] = 0;
                        samples[sample_idx+1] = 0;
                    end
                    #0.01;
                end
            end
 
            $fclose(f);
            #0.01;

        end    


        f = $fopen($sformatf("simulation_output_blast.txt", sample_idx), "w");
        for(k=0; k<500; k = k+1) begin
            @(posedge clk);
            // Writing very explicitly
            $fwrite(f, "%b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b\n",
                        sample_arr[1*12-1 -:12],
                        sample_arr[2*12-1 -:12],
                        sample_arr[3*12-1 -:12],
                        sample_arr[4*12-1 -:12],
                        sample_arr[5*12-1 -:12],
                        sample_arr[6*12-1 -:12],
                        sample_arr[7*12-1 -:12],
                        sample_arr[8*12-1 -:12],

                        outsample_arr[1*12-1 -:12],
                        outsample_arr[2*12-1 -:12],
                        outsample_arr[3*12-1 -:12],
                        outsample_arr[4*12-1 -:12],
                        outsample_arr[5*12-1 -:12],
                        outsample_arr[6*12-1 -:12],
                        outsample_arr[7*12-1 -:12],
                        outsample_arr[8*12-1 -:12],

                        outsampleB_arr[1*12-1 -:12],
                        outsampleB_arr[2*12-1 -:12],
                        outsampleB_arr[3*12-1 -:12],
                        outsampleB_arr[4*12-1 -:12],
                        outsampleB_arr[5*12-1 -:12],
                        outsampleB_arr[6*12-1 -:12],
                        outsampleB_arr[7*12-1 -:12],
                        outsampleB_arr[8*12-1 -:12]  );
            // if(k>2 && k<10) begin
            //     samples[0] = 1000;
            //     samples[1] = 1000;
            // end else begin
            //     samples[0] = 0;
            //     samples[1] = 0;
            // end
            if(k==100) begin
                samples[0] = 12'b001111101000;//-1,000
                samples[1] = 12'b001111101000;//-1,000
                samples[2] = 12'b001111101000;//-1,000
                samples[3] = 12'b001111101000;//-1,000
                samples[4] = 12'b001111101000;//-1,000
                samples[5] = 12'b001111101000;//-1,000
                samples[6] = 12'b001111101000;//-1,000
                samples[7] = 12'b001111101000;//-1,000
                //                    
            // end else if(k==101) begin
            //     samples[0] = 0   ;
            //     samples[1] = 1000;
            end else begin
                samples[0] = 0;//-1,000
                samples[1] = 0;//-1,000
                samples[2] = 0;//-1,000
                samples[3] = 0;//-1,000
                samples[4] = 0;//-1,000
                samples[5] = 0;//-1,000
                samples[6] = 0;//-1,000
                samples[7] = 0;//-1,000
            end
            #0.01;
        end
        $fclose(f);
        #0.01;
       
    end

endmodule
