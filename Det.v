/* Module for calculating the determinant of a tridiagonal matrix.
   Built to interact with SRAM. 
   Daniel Sami
   Fall 2016
*/

`define WRITE_ADDRESS_POSITION 4'b1110 
`define COUNTER_INIT_VALUE 4'b1110

module Det (clock, reset,go,readAddress, writeAddress,
	    WE,readbus,writebus,overflow,finished);
	input clock;
	input reset; 
    	input go;

	input 	   [31:0] 	readbus;        // 32 bit read bus
	output reg [31:0]	writebus;  	    //32-bit write bus
	output reg [6:0] 	readAddress; 	// read address
	output reg [6:0]	writeAddress; 	// write address
	
    	output reg WE;

    	output     overflow; 	//overflow signal
    	output reg finished;	//finished is high when operation is done.
        
    reg [3:0] counter;  //4bit counter to iterate through SRAM	

    // for determinant input
    reg signed  [15:0] A, B, C;
    wire signed [31:0] BC, subtrahend, minuend, diff;
    reg signed  [31:0] FnMinusOne, FnMinusTwo;
    reg [3:0]  state, next_state;

    parameter WAIT          = 0;
    parameter ITERATE_A     = 1;
    parameter ITERATE_B    = 2;
    parameter WRITE_TO_SRAM = 3;
    parameter DONE          = 4;

    // FSM
    always@(posedge clock) begin
        if(!reset) state <= WAIT;
        else state <= next_state;
    end

    always@(posedge clock) begin
        
        case(state)

            // State waiting for go.
            WAIT: begin
                writebus    <= 0;
                writeAddress<= 14;
                readAddress <= 0;
                finished    <= 0;
                WE          <= 0;
                A           <= 0;
                B           <= 0;
                C           <= 0;
                FnMinusOne  <= 1;
                FnMinusTwo  <= 0;
                counter     <= `COUNTER_INIT_VALUE;
                if(go) next_state <= ITERATE_B;
                else if(next_state <= ITERATE_B) next_state <= next_state;
                else next_state <= WAIT;
                if(finished) begin
                    if(go) next_state <= ITERATE_B;
                    else   next_state <= WAIT;
                end
            end

            // Even scanning states
            ITERATE_A: begin
                writebus    <= writebus;
                finished    <= finished;
                WE          <= WE;
                next_state  <= ITERATE_B;
                readAddress <= readAddress + 1;
                if(next_state == ITERATE_B) begin
                    A           <= A;
                    B           <= readbus[31:16];
                    C           <= readbus[15:0];
                    FnMinusOne  <= diff;
                    FnMinusTwo  <= FnMinusOne;
                    counter     <= counter - 1;
                    if (!counter) begin 
                        next_state  <= WRITE_TO_SRAM;
                        writebus    <= diff;
                    end
                    else begin
                        next_state <= ITERATE_B;
                        writebus   <= writebus;
                    end
                end
                else begin
                    A           <= readbus[15:0];
                    B           <= B;
                    C           <= readbus[31:16];
                    FnMinusOne  <= FnMinusOne;
                    FnMinusTwo  <= FnMinusTwo;
                    counter     <= counter - 1;
                end
            end
            // Odd scanning states
            ITERATE_B: begin
                writebus    <= writebus;
                finished    <= finished;
                WE          <= WE;
                C           <= C;
                next_state  <= ITERATE_A;
                if(next_state == ITERATE_A) begin
                    readAddress <= readAddress + 1;
                    A           <= A;
                    B           <= readbus[15:0];
                    FnMinusOne  <= diff;
                    FnMinusTwo  <= FnMinusOne;
                    counter     <= counter - 1;
                end
                else begin
                    readAddress <= readAddress;
                    A           <= readbus[31:16];
                    B           <= B;
                    FnMinusOne  <= FnMinusOne;
                    FnMinusTwo  <= FnMinusTwo;
                    counter     <= counter;
                end
            end
            // State that writes to SRAM
            WRITE_TO_SRAM: begin
                WE  <= 1;
                next_state <= DONE;
            end

            // Completion state
            DONE: begin
                WE <= 0;
                finished <= 1;
                next_state <= WAIT;
            end

        endcase
    end

    assign BC           = B * C;
    assign minuend      = FnMinusOne * A;
    assign subtrahend   = BC * FnMinusTwo;
    assign diff         = minuend - subtrahend;
    assign overflow     = 0;

endmodule
