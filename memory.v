// Behavior memory model with address mapping
// Author: Chun-Yen Yao

module memory #(
        parameter BITS = 32,
        parameter word_depth = 32
    ) (
        clk,
        rst_n,
        wen,
        a,
        d,
        q,
        offset
    );
       
    input clk, rst_n, wen; // wen: 0:read | 1:write
    input [BITS-1:0] d;
    input [BITS-1:0] a;


    output [BITS-1:0] q;

    input [31:0] offset;

    reg  [BITS-1:0] q;
    reg  [BITS-1:0] mem [0:word_depth-1];
    reg  [BITS-1:0] mem_nxt [0:word_depth-1];
    reg  [BITS-1:0] mem_addr [0:word_depth-1];

    integer i;

    always @(*) begin
        q = {(BITS){1'bz}};
        for (i=0; i<word_depth; i=i+1) begin
            if (mem_addr[i] == a)
                q = mem[i];
        end
    end

    always @(negedge rst_n) begin
        mem_addr[0] = offset;
        for (i=1; i<word_depth; i=i+1)
            mem_addr[i] = mem_addr[i-1]+4;
    end

    always @(*) begin
        for (i=0; i<word_depth; i=i+1)
            mem_nxt[i] = (wen && (mem_addr[i] == a)) ? d : mem[i];
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0; i<word_depth; i=i+1)
                mem[i] <= 0;
        end
        else begin
            for (i=0; i<word_depth; i=i+1)
                mem[i] <= mem_nxt[i];    
        end
    end

endmodule