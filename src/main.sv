/*

Successive Aproximation Register Analog-to-Digital Convertor main module.

Toby Wright, github.com/tobywr

*/



`timescale 1ns/1ps

module main #(
	parameter DATA_WIDTH = 8
	)(
	input logic clk,
	input logic rst_n,

	input logic [DATA_WIDTH-1:0] Vin,
	input logic SAR_ena, 
	input logic [DATA_WIDTH-1:0] Vref,

	output logic [DATA_WIDTH-1:0] V_Out,
	output logic SAR_complete
);

	assign V_Out = ADC;

	//sample and hold logic.

	logic [DATA_WIDTH-1:0] Vin_held;

	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			Vin_held <= '0;
		end else if (state == IDLE && next_state == SET_BIT) begin
			Vin_held <= Vin;
		end
	end

	//DAC logic
	logic [DATA_WIDTH-1:0] DAC;
    logic [DATA_WIDTH-1:0] DAC_Analog;
    assign DAC_Analog = ({8'd0, DAC} * {8'd0, Vref}) >> 8;
	//comparator logic
	logic comparator_out;
	assign comparator_out = (DAC_Analog >= Vin_held);

	//FSM logic
	typedef enum logic [2:0] {
		IDLE,
		SET_BIT,
		COMPARE,
		DECIDE,
		DONE
	} state_t;

	state_t state, next_state;

	//internal logic for FSM
	logic [DATA_WIDTH-1:0] DAC_NEXT;
	logic [DATA_WIDTH-1:0] ADC;
	logic [DATA_WIDTH-1:0] ADC_NEXT;
	logic [2:0] bit_count_next;
	logic [2:0] bit_count;
	//state updator.
	always_ff @(posedge clk or negedge rst_n) begin
	    if (!rst_n) begin
	        state <= IDLE;
	        bit_count <= 3'd7;
	    end else begin 
	        state <= next_state;
	        DAC <= DAC_NEXT;
	        ADC <= ADC_NEXT;
	        bit_count <= bit_count_next;
	    end
	end

	always_comb begin
		DAC_NEXT = DAC;
		ADC_NEXT = ADC;
		bit_count_next = bit_count;
		next_state = state;
		SAR_complete = '0;
		case (state)
			IDLE: begin
				DAC_NEXT = '0;
				bit_count_next = 3'd7;
				SAR_complete = '0;
				if (SAR_ena) next_state = SET_BIT;
				else next_state = IDLE;
			end

			SET_BIT: begin
				DAC_NEXT[bit_count] = 1'b1;
				next_state = COMPARE;
			end

			COMPARE: begin
                //Give time for comparator and DAC logic to settle.
                next_state = DECIDE;
            end
            
            DECIDE: begin
                if (bit_count > 0) begin
                    if (comparator_out == 1'b1) begin
                        DAC_NEXT[bit_count] = 1'b0; //high so clear bit.
                    end
                    bit_count_next = bit_count - 1;
                    next_state = SET_BIT;
                end else begin
                    if (comparator_out == 1'b1) begin
                        DAC_NEXT[bit_count] = 1'b0;
                    end
                    next_state = DONE;
                end
            end

			DONE: begin
				ADC_NEXT = DAC;
				SAR_complete = '1;
				next_state = IDLE;
			end

			default: next_state = IDLE;
		endcase
	end

endmodule