typedef logic signed [31:0] num_t;

module pe(i_a, i_b, clk, rst_n, o_a, o_b, o_sum);
    input num_t i_a, i_b; 
    input logic clk, rst_n;
    output num_t o_a, o_b, o_sum;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            o_sum <= 0;
            o_a <= 0;
            o_b <= 0;
        end else begin
            o_sum <= o_sum + i_a * i_b;
            o_a <= i_a;
            o_b <= i_b;
        end
    end
endmodule

module systolic_array #(parameter N=4) (clk, rst_n, i_mat_a, i_mat_b, o_mat);
    input logic clk, rst_n;
    input num_t i_mat_a [N-1:0][N-1:0], i_mat_b [N-1:0][N-1:0];
    output num_t o_mat [N-1:0][N-1:0];

    logic [$clog2(2*N-1)-1:0] ticks;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ticks <= 0;
        else if (ticks < 2*N-1) 
            ticks <= ticks + 1;
    end

    num_t feed_a [N-1:0];
    num_t feed_b [N-1:0];
    always_comb begin
        for (int i = 0; i < N; i++) begin
            feed_a[i] = (ticks >= i && ticks < i + N) ? i_mat_a[i][ticks - i] : 0;
            feed_b[i] = (ticks >= i && ticks < i + N) ? i_mat_b[ticks - i][i] : 0;
        end
    end

    num_t a_wire [N-1:0][N-1:0];
    num_t b_wire [N-1:0][N-1:0];

    genvar i, j;
    generate
        for (i = 0; i < N; i++) begin
            for (j = 0; j < N; j++) begin
                pe pe_inst (
                    .i_a((i==0) ? feed_a[j] : a_wire[i-1][j]),
                    .i_b((j==0) ? feed_b[i] : b_wire[i][j-1]),
                    .clk(clk),
                    .rst_n(rst_n),
                    .o_a(a_wire[i][j]),
                    .o_b(b_wire[i][j]),
                    .o_sum(o_mat[j][i])
                );
            end
        end
    endgenerate
endmodule
