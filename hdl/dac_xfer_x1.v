`timescale 1ns / 1ps
// Test to see if switching the DACs to operate at 8 samples works
module dac_xfer_x1 #(parameter DWIDTH_IN=128,
                     parameter DWIDTH_OUT=128)(
        input aclk,
        input aresetn,
        // tvalid/tready here are just lies        
        input [DWIDTH_IN-1:0] s_axis_tdata,
        input                 s_axis_tvalid,
        output                s_axis_tready,
              
        output [DWIDTH_OUT-1:0] m_axis_tdata,
        output                  m_axis_tvalid,
        input                   m_axis_tready        
    );     

    reg [127:0] dout_rereg = {128{1'b0}}; // Changed since last test
    
    always @(posedge aclk) begin
        dout_rereg <= {8{s_axis_tdata[15:0]}};
    end
        
    assign m_axis_tvalid = 1'b1;
    assign m_axis_tdata = dout_rereg;
    
endmodule
