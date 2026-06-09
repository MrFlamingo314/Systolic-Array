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
        for (int i = 0; i < 10; i++) begin
            random_test();
            #(30*N+20); // Wait for the computation to complete
        end
        
        $finish;
    end
endmodule

task automatic compare(mat_a, mat_b, mat_o);

    input logic signed [31:0] mat_a [N-1:0][N-1:0];
    input logic signed [31:0] mat_b [N-1:0][N-1:0];
    input logic signed [31:0] mat_o [N-1:0][N-1:0];

    for (int i = 0; i < N; i++)
        for (int j = 0; j < N; j++) begin
            logic signed [31:0] expected = 0;
            for (int k = 0; k < N; k++)
                expected += mat_a[i][k] * mat_b[k][j];
            assert(mat_o[i][j] == expected)
                else $error("Mismatch [%0d][%0d]: expected %0d got %0d",
                            i, j, expected, mat_o[i][j]);
        end
    
endtask
    
task automatic random_test();
    logic signed [31:0] mat_a [N-1:0][N-1:0];
    logic signed [31:0] mat_b [N-1:0][N-1:0];
    logic signed [31:0] mat_o [N-1:0][N-1:0];

    $display(list_of_arguments)
    for (int i = 0; i < N; i++)
        for (int j = 0; j < N; j++) begin
            mat_a[i][j] = $random;
            mat_b[i][j] = $random;
        end

    compare(mat_a, mat_b, mat_c);
