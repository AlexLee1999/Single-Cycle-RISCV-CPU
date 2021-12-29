module CHIP(clk,
            rst_n,
            // For mem_D
            mem_wen_D,
            mem_addr_D,
            mem_wdata_D,
            mem_rdata_D,
            // For mem_I
            mem_addr_I,
            mem_rdata_I);

    input         clk, rst_n ;
    // For mem_D
    output        mem_wen_D  ;
    output [31:0] mem_addr_D ;
    output [31:0] mem_wdata_D;
    input  [31:0] mem_rdata_D;
    // For mem_I
    output [31:0] mem_addr_I ;
    input  [31:0] mem_rdata_I;

    //---------------------------------------//
    // Do not modify this part!!!            //
    // Exception: You may change wire to reg //
    reg    [31:0] PC          ;              //
    reg    [31:0] PC_nxt      ;              //
    reg           regWrite    ;              //
    wire   [ 4:0] rs1, rs2, rd;              //
    wire   [31:0] rs1_data    ;              //
    wire   [31:0] rs2_data    ;              //
    reg    [31:0] rd_data     ;              //
    //---------------------------------------//

    // Todo: other wire/reg
    wire        do_multiply, ready_multiply, is_eq;
    wire [2:0]  memtoreg_case, func3, PC_case;
    wire [3:0]  aluin_case;
    wire [6:0]  opcode, func7;
    wire [31:0] Instruction, PC_add_four, PC_add_imm, rs1_add_imm, ALUin1, ALUin2;
    wire [63:0] multiply_result;
    reg         branch, jal, jalr, ALUsrc, memRead, memWrite, Zero, do_auipc, do_jump, memToReg, doing_multiply;
    reg  [1:0]  ALUop;
    reg  [3:0]  ALU_ctrl;
    reg  [31:0] Immediate, ALU_out;
    //---------------------------------------//
    // Do not modify this part!!!            //
    reg_file reg0(                           //
        .clk(clk),                           //
        .rst_n(rst_n),                       //
        .wen(regWrite),                      //
        .a1(rs1),                            //
        .a2(rs2),                            //
        .aw(rd),                             //
        .d(rd_data),                         //
        .q1(rs1_data),                       //
        .q2(rs2_data));                      //
    //---------------------------------------//

    // Todo: any combinational/sequential circuit
    assign Instruction = mem_rdata_I;
    assign mem_addr_I = PC;
    assign func7  = Instruction[31:25];
    assign rs2    = Instruction[24:20];
    assign rs1    = Instruction[19:15];
    assign func3  = Instruction[14:12];
    assign rd     = Instruction[11: 7];
    assign opcode = Instruction[6 : 0];
    assign mem_wen_D = memWrite; //mem_wen_D = 1 write


    parameter R_TYPE = 7'b0110011;
    parameter I_TYPE = 7'b0010011;
    parameter I_JALR = 7'b1100111;
    parameter S_TYPE = 7'b0100011;
    parameter B_TYPE = 7'b1100011;
    parameter JAL    = 7'b1101111;
    parameter AUIPC  = 7'b0010111;
    parameter LOAD   = 7'b0000011;

    assign do_multiply = (func7 == 7'b0000001) & (opcode == R_TYPE);
    always@(*) begin
          if(do_multiply) begin
              if(!ready_multiply) begin
                  doing_multiply = 1'b1;
              end
              else begin
                  doing_multiply = 1'b0;
              end
          end
          else begin
              doing_multiply = 1'b0;
          end
    end

    mulDiv mul0(
        .clk(clk),
        .rst_n(rst_n),
        .valid(do_multiply),
        .ready(ready_multiply),
        .mode(1'b0),
        .in_A(rs1_data),
        .in_B(rs2_data),
        .out(multiply_result));

// Control Unit && Immediate generation
    always@(*) begin
        case (opcode)
            R_TYPE : begin
                branch   = 1'b0;
                jal      = 1'b0;
                jalr     = 1'b0;
                ALUsrc   = 1'b0;
                memWrite = 1'b0;
                regWrite = !(do_multiply & doing_multiply);
                memToReg = 1'b0;
                do_jump  = 1'b0;
                do_auipc = 1'b0;
                ALUop    = 2'b10;
                Immediate = 32'b0;
            end
            I_TYPE : begin
                branch   = 1'b0;
                jal      = 1'b0;
                jalr     = 1'b0;
                ALUsrc   = 1'b1;
                memWrite = 1'b0;
                regWrite = 1'b1;
                memToReg = 1'b0;
                do_jump  = 1'b0;
                do_auipc = 1'b0;
                ALUop    = 2'b10;
                if (!Instruction[31])
                    Immediate = {21'b0, Instruction[30:20]};
                else
                    Immediate = {21'b111111111111111111111, Instruction[30:20]};
            end
            I_JALR: begin
                branch   = 1'b0;
                jal      = 1'b0;
                jalr     = 1'b1;
                ALUsrc   = 1'b1;
                memWrite = 1'b0;
                regWrite = 1'b1;
                memToReg = 1'b0;
                do_jump  = 1'b1;
                do_auipc = 1'b0;
                ALUop    = 2'b00;
                if (!Instruction[31])
                    Immediate = {21'b0, Instruction[30:21], Instruction[20]};
                else
                    Immediate = {21'b111111111111111111111, Instruction[30:21], Instruction[20]};
            end
            S_TYPE: begin
                branch   = 1'b0;
                jal      = 1'b0;
                jalr     = 1'b0;
                ALUsrc   = 1'b1;
                memWrite = 1'b1;
                regWrite = 1'b0;
                memToReg = 1'b0;
                do_jump  = 1'b0;
                do_auipc = 1'b0;
                ALUop    = 2'b00;
                if (!Instruction[31])
                    Immediate = {21'b0, Instruction[30:25], Instruction[11:8], Instruction[7]};
                else
                    Immediate = {21'b111111111111111111111, Instruction[30:25], Instruction[11:8], Instruction[7]};
            end
            B_TYPE: begin
                branch   = 1'b1;
                jal      = 1'b0;
                jalr     = 1'b0;
                ALUsrc   = 1'b0;
                memWrite = 1'b0;
                regWrite = 1'b0;
                memToReg = 1'b0;
                do_jump  = 1'b0;
                do_auipc = 1'b0;
                ALUop    = 2'b01;
                if (!Instruction[31])
                    Immediate = {20'b0, Instruction[7], Instruction[30:25], Instruction[11:8], 1'b0};
                else
                    Immediate = {20'b11111111111111111111, Instruction[7], Instruction[30:25], Instruction[11:8], 1'b0};
            end
            JAL: begin
                branch   = 1'b0;
                jal      = 1'b1;
                jalr     = 1'b0;
                ALUsrc   = 1'b0;
                memWrite = 1'b0;
                regWrite = 1'b1;
                memToReg = 1'b0;
                do_jump  = 1'b1;
                do_auipc = 1'b0;
                ALUop    = 2'b00;
                if (!Instruction[31])
                    Immediate = {12'b0, Instruction[19:12], Instruction[20], Instruction[30:21], 1'b0};
                else
                    Immediate = {12'b111111111111, Instruction[19:12], Instruction[20], Instruction[30:21], 1'b0};
            end
            AUIPC: begin
                branch   = 1'b0;
                jal      = 1'b0;
                jalr     = 1'b0;
                ALUsrc   = 1'b0;
                memWrite = 1'b0;
                regWrite = 1'b1;
                memToReg = 1'b0;
                do_jump  = 1'b0;
                do_auipc = 1'b1;
                ALUop    = 2'b00;
                if (!Instruction[31])
                    Immediate = {13'b0, Instruction[30:12]};
                else
                    Immediate = {13'b1111111111111, Instruction[30:12]};
            end
            LOAD: begin
                branch   = 1'b0;
                jal      = 1'b0;
                jalr     = 1'b0;
                ALUsrc   = 1'b1;
                memWrite = 1'b0;
                regWrite = 1'b1;
                memToReg = 1'b1;
                do_jump  = 1'b0;
                do_auipc = 1'b0;
                ALUop    = 2'b00;
                if (!Instruction[31])
                    Immediate = {21'b0, Instruction[30:20]};
                else
                    Immediate = {21'b111111111111111111111, Instruction[30:20]};
            end
            default: begin
                branch   = 1'b0;
                jal      = 1'b0;
                jalr     = 1'b0;
                ALUsrc   = 1'b0;
                memWrite = 1'b0;
                regWrite = 1'b0;
                memToReg = 1'b0;
                do_jump  = 1'b0;
                do_auipc = 1'b0;
                ALUop    = 2'b00;
                Immediate = 32'b0;
            end
        endcase
    end
// ALUctrl
    always@(*) begin
        case (ALUop)
        2'b00:
            ALU_ctrl = 4'b0000; // ADD
        2'b01:
            ALU_ctrl = 4'b1000; // SUB
        2'b10: begin
            if (opcode == R_TYPE) begin //R-type
                ALU_ctrl = {Instruction[30], func3}; // ADD, SUB, AND, OR, XOR
            end
            else begin
                if (func3 == 3'b101)
                    ALU_ctrl = {Instruction[30], func3}; //SRAI, SRLI
                else
                    ALU_ctrl = {1'b0, func3}; // SLTI, ADDI, SLLI
            end

        end
        default:
            ALU_ctrl = 4'b0000;
        endcase
    end
    assign  ALUin1 = rs1_data;
    assign  ALUin2 = ALUsrc ? Immediate : rs2_data;
// ALU
    always@(*) begin
        if(!do_multiply) begin
            Zero = 0;
            case (ALU_ctrl)
            4'b0000: // ADD
                ALU_out = ALUin1 + ALUin2;
            4'b1000: begin // SUB
                ALU_out = ALUin1 - ALUin2;
                if (ALU_out == 32'b0)
                    Zero = 1;
                else
                    Zero = 0;
            end
            4'b0010: // SLTI
                ALU_out = ( $signed( ALUin1 ) < $signed( ALUin2 ) ) ? 32'b1 : 32'b0;
            4'b0001: // SLLI
                ALU_out = ALUin1 << ALUin2;
            4'b0101: // SRLI
                ALU_out = ALUin1 >> ALUin2;
            4'b1101: // SRAI
                ALU_out = $signed( ALUin1 ) >>> ALUin2;
            4'b0110: // OR
                ALU_out = ALUin1 | ALUin2;
            4'b0111: // AND
                ALU_out = ALUin1 & ALUin2;
            4'b0100: // XOR
                ALU_out = ALUin1 ^ ALUin2;
            default:
                ALU_out = 32'b0;
            endcase
        end
        else
            if (ready_multiply) //IF do multiply, check the result
                ALU_out = multiply_result[31:0];
            else
                ALU_out = 32'b0;
    end

    assign rs1_add_imm = rs1_data + Immediate;
    assign mem_wdata_D = rs2_data;
    assign mem_addr_D  = ALU_out;
    assign PC_add_four  = PC + 32'd4;
    assign PC_add_imm   = PC + Immediate;
    assign memtoreg_case = {memToReg, do_jump, do_auipc};

    // memtoreg cases
    parameter NORMAL  = 3'b000;
    parameter DOLOAD  = 3'b100;
    parameter DOJUMP  = 3'b010;
    parameter DOAUIPC = 3'b001;

    always@(*) begin
        case(memtoreg_case)
            NORMAL:
                rd_data = ALU_out;
            DOLOAD:
                rd_data = mem_rdata_D;
            DOJUMP:
                rd_data = PC_add_four;
            DOAUIPC:
                rd_data = PC_add_imm;
            default:
                rd_data = 32'b0;
        endcase
    end
    assign is_eq = (Zero & branch);
    assign PC_case = {is_eq, jal, jalr};

    always @(*) begin
        case(PC_case)
            3'b100:
                PC_nxt = PC_add_imm;
            3'b010:
                PC_nxt = PC_add_imm;
            3'b001:
                PC_nxt = rs1_add_imm;
            default:
                PC_nxt = PC_add_four;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            PC <= 32'h00010000; // Do not modify this value!!!
        end
        else if(!doing_multiply) begin // If doing Mul, don't change the PC
            PC <= PC_nxt;
        end
    end

endmodule

module reg_file(clk, rst_n, wen, a1, a2, aw, d, q1, q2);

    parameter BITS = 32;
    parameter word_depth = 32;
    parameter addr_width = 5; // 2^addr_width >= word_depth

    input clk, rst_n, wen; // wen: 0:read | 1:write
    input [BITS-1:0] d;
    input [addr_width-1:0] a1, a2, aw;

    output [BITS-1:0] q1, q2;

    reg [BITS-1:0] mem [0:word_depth-1];
    reg [BITS-1:0] mem_nxt [0:word_depth-1];

    integer i;

    assign q1 = mem[a1];
    assign q2 = mem[a2];

    always @(*) begin
        for (i=0; i<word_depth; i=i+1)
            mem_nxt[i] = (wen && (aw == i)) ? d : mem[i];
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem[0] <= 0;
            for (i=1; i<word_depth; i=i+1) begin
                case(i)
                    32'd2: mem[i] <= 32'hbffffff0;
                    32'd3: mem[i] <= 32'h10008000;
                    default: mem[i] <= 32'h0;
                endcase
            end
        end
        else  begin
            mem[0] <= 0;
            for (i=1; i<word_depth; i=i+1)
                mem[i] <= mem_nxt[i];
        end
    end
endmodule

module mulDiv(
    clk,
    rst_n,
    valid,
    ready,
    mode,
    in_A,
    in_B,
    out
);

    // Definition of ports
    input         clk, rst_n;
    input         valid, mode; // mode: 0: mulu, 1: divu
    output        ready;
    input  [31:0] in_A, in_B;
    output [63:0] out;

    // Definition of states
    parameter IDLE = 2'b00;
    parameter MUL  = 2'b01;
    parameter DIV  = 2'b10;
    parameter OUT  = 2'b11;

    // Todo: Wire and reg if needed
    reg  [ 1:0] state, state_nxt;
    reg  [ 4:0] counter, counter_nxt;
    reg  [63:0] shreg, shreg_nxt;
    reg  [31:0] alu_in, alu_in_nxt;
    reg  [32:0] alu_out;

    // Todo: Instatiate any primitives if needed

    // Todo 5: Wire assignments
    assign ready = (state == OUT) ? 1'b1 : 1'b0;
    assign out = (ready == 1'b1) ? shreg : 64'b0;

    // Combinational always bdoing_multiply
    // Todo 1: Next-state logic of state machine
    always @(*) begin
        case(state)
            IDLE: begin
                state_nxt	=	IDLE;
                case(valid)
                    1'b0:
                        state_nxt	=	IDLE;
                    1'b1:
                        state_nxt	=	(mode == 1'b1) ? DIV:MUL;
                    default:
                        state_nxt	=	IDLE;
                endcase
            end
            MUL :
                state_nxt	=	(counter == 5'd31) ? OUT : MUL;
            DIV :
                state_nxt	=	(counter == 5'd31) ? OUT : DIV;
            OUT :
                state_nxt = IDLE;
            default:
                state_nxt = IDLE;
        endcase
    end

    // Todo 2: Counter
    always @(*) begin
    	case (state)
  	    IDLE: counter_nxt = 0;
  	    OUT: counter_nxt = 0;
  	    MUL: counter_nxt = counter + 1; // If state = MUL, DIV, counter++, else counter = 0
  	    DIV: counter_nxt = counter + 1;
	    endcase
    end

    // ALU input
    always @(*) begin
        case (state)
            IDLE: begin
                if (valid)
                  alu_in_nxt = in_B;
                else
                  alu_in_nxt = 0;
            end
            OUT: alu_in_nxt = 0;
            default: alu_in_nxt = alu_in; // MUL, DIV
        endcase
    end

    // Todo 3: ALU output
    always @(*) begin
	   case (state)
      IDLE: alu_out = 32'b0;
	    MUL: begin
      	if (shreg[0] == 1'b1)
          alu_out = shreg[63:32] + alu_in; // If Shift reg[0] == 1, add Multiplier
      	else
          alu_out = shreg[63:32];
	    end
	    DIV: begin
		    alu_out = shreg[63:32] - alu_in; // Minus the Divisor
	    end
      OUT: alu_out = 32'b0;
	  endcase
    end

    // Todo 4: Shift register
    always @(*) begin
    case (state)
      IDLE: begin
        if (valid) begin
          if (mode == 1'b1)
            shreg_nxt = {31'b0, in_A, 1'b0}; // If Mode is division, Shift Left and add Zero
          else
            shreg_nxt = {32'b0, in_A};
        end
        else shreg_nxt = shreg;
      end
      MUL: begin
        shreg_nxt = {1'b0, alu_out, shreg[31:1]}; //shift right
      end
      DIV: begin
        if (counter == 5'b11111) begin
          if (alu_out[31] == 1'b1) // if the alu_out is negative
            shreg_nxt = {1'b0, shreg[62:32], shreg[30:0], 1'b0}; // restore the initial value
          else
            shreg_nxt = {1'b0, alu_out[30:0], shreg[30:0], 1'b1}; //shift right in the left half
        end
        else begin
          if (alu_out[31] == 1)
            shreg_nxt = {shreg[62:0], 1'b0}; // restore the initial value
          else
            shreg_nxt = {alu_out[30:0], shreg[31:0], 1'b1}; // shift left and add 1 in the right
        end
      end
      OUT: shreg_nxt = shreg;
    endcase
    end

    // Todo: Sequential always bdoing_multiply
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          state <= IDLE;
          counter <= 0;
        end
        else begin
          state <= state_nxt;
    	    counter <= counter_nxt;
          alu_in <= alu_in_nxt;
    	    shreg <= shreg_nxt;
        end
    end
endmodule
