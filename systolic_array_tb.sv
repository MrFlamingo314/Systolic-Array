`timescale 1ns/1ps

module systolic_array_tb #(parameter N=4) ();
    logic clk, rst_n;
    logic signed [31:0] i_mat_a [N-1:0][N-1:0];
    logic signed [31:0] i_mat_b [N-1:0][N-1:0];
    logic signed [31:0] o_mat   [N-1:0][N-1:0];

    systolic_array #(.N(N)) Array (
        .clk(clk),
        .rst_n(rst_n),
        .i_mat_a(i_mat_a),
        .i_mat_b(i_mat_b),
        .o_mat(o_mat)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, systolic_array_tb);
        rst_n = 0;
        #10 rst_n = 1;

        for (int i = 0; i < N; i++)
            for (int j = 0; j < N; j++) begin
                i_mat_a[i][j] = i + j;
                i_mat_b[i][j] = (i == j) ? 1 : 0;
            end

        #200;

        $display("Calculated:");
        for (int i = 0; i < N; i++) begin
            for (int j = 0; j < N; j++) $write("%0d ", o_mat[i][j]);
            $write("\n");
        end

        for (int i = 0; i < N; i++)
            for (int j = 0; j < N; j++)
                assert(o_mat[i][j] == i_mat_a[i][j])
                    else $error("Mismatch [%0d][%0d]: expected %0d got %0d",
                                i, j, i_mat_a[i][j], o_mat[i][j]);

        $display("Test completed!");
        $finish;
    end
endmodule