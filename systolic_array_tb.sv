`timescale 1ns/1ps

module systolic_array_tb #(parameter N=4) ();
    logic clk, rst_n;
    logic signed [31:0] i_mat_a [N-1:0][N-1:0];
    logic signed [31:0] i_mat_b [N-1:0][N-1:0];
    logic signed [31:0] o_mat   [N-1:0][N-1:0];
    logic signed [31:0] expected [N-1:0][N-1:0];

    // Track test results
    int tests_passed;
    int tests_failed;

    systolic_array #(.N(N)) Array (
        .clk(clk),
        .rst_n(rst_n),
        .i_mat_a(i_mat_a),
        .i_mat_b(i_mat_b),
        .o_mat(o_mat)
    );

    localparam WAIT_TIME = (3*N + 2) * 10;

    initial clk = 0;
    always #5 clk = ~clk;

    // ----------------------------------------------------------------
    // Task: reset the array
    // ----------------------------------------------------------------
    task do_reset();
        rst_n = 0;
        #20;
        rst_n = 1;
    endtask

    // ----------------------------------------------------------------
    // Task: compute expected result (software matrix multiply)
    // ----------------------------------------------------------------
    task compute_expected();
        for (int i = 0; i < N; i++)
            for (int j = 0; j < N; j++) begin
                expected[i][j] = 0;
                for (int k = 0; k < N; k++)
                    expected[i][j] += i_mat_a[i][k] * i_mat_b[k][j];
            end
    endtask

    // ----------------------------------------------------------------
    // Task: wait and check output against expected
    // ----------------------------------------------------------------
    task check_result(input string test_name);
        int pass;
        pass = 1;
        #(WAIT_TIME);

        $display("\n=== %s ===", test_name);
        $display("Output:");
        for (int i = 0; i < N; i++) begin
            for (int j = 0; j < N; j++) $write("%6d ", o_mat[i][j]);
            $write("\n");
        end

        for (int i = 0; i < N; i++)
            for (int j = 0; j < N; j++)
                if (o_mat[i][j] !== expected[i][j]) begin
                    $error("FAIL [%0d][%0d]: expected %0d got %0d",
                           i, j, expected[i][j], o_mat[i][j]);
                    pass = 0;
                end

        if (pass) begin
            $display("PASS");
            tests_passed++;
        end else begin
            tests_failed++;
        end
    endtask

    // ----------------------------------------------------------------
    // Main test sequence
    // ----------------------------------------------------------------
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, systolic_array_tb);
        tests_passed = 0;
        tests_failed = 0;

        // ------------------------------------------------------------
        // TEST 1: Identity matrix (original test)
        // A = [[i+j]], B = identity ? output should equal A
        // ------------------------------------------------------------
        do_reset();
        for (int i = 0; i < N; i++)
            for (int j = 0; j < N; j++) begin
                i_mat_a[i][j] = i + j;
                i_mat_b[i][j] = (i == j) ? 1 : 0;
            end
        compute_expected();
        check_result("TEST 1: A x Identity");

        // ------------------------------------------------------------
        // TEST 2: Zero matrix
        // A = anything, B = all zeros ? output should be all zeros
        // ------------------------------------------------------------
        do_reset();
        for (int i = 0; i < N; i++)
            for (int j = 0; j < N; j++) begin
                i_mat_a[i][j] = $urandom_range(100, 1);
                i_mat_b[i][j] = 0;
            end
        compute_expected();
        check_result("TEST 2: A x Zero");

        // ------------------------------------------------------------
        // TEST 3: All-ones matrices
        // Every element of output should equal N
        // ------------------------------------------------------------
        do_reset();
        for (int i = 0; i < N; i++)
            for (int j = 0; j < N; j++) begin
                i_mat_a[i][j] = 1;
                i_mat_b[i][j] = 1;
            end
        compute_expected();
        check_result("TEST 3: Ones x Ones");

        // ------------------------------------------------------------
        // TEST 4: Random matrices (unsigned small values)
        // ------------------------------------------------------------
        do_reset();
        for (int i = 0; i < N; i++)
            for (int j = 0; j < N; j++) begin
                i_mat_a[i][j] = $urandom_range(15, 0);
                i_mat_b[i][j] = $urandom_range(15, 0);
            end
        compute_expected();
        check_result("TEST 4: Random (0-15)");

        // ------------------------------------------------------------
        // TEST 5: Random matrices with negative values
        // ------------------------------------------------------------
        do_reset();
        for (int i = 0; i < N; i++)
            for (int j = 0; j < N; j++) begin
                i_mat_a[i][j] = $random % 16;  // -15 to +15
                i_mat_b[i][j] = $random % 16;
            end
        compute_expected();
        check_result("TEST 5: Random with negatives");

        // ------------------------------------------------------------
        // TEST 6: Diagonal matrix
        // B = diagonal with values 1..N ? scales each column of A
        // ------------------------------------------------------------
        do_reset();
        for (int i = 0; i < N; i++)
            for (int j = 0; j < N; j++) begin
                i_mat_a[i][j] = $urandom_range(10, 1);
                i_mat_b[i][j] = (i == j) ? (i + 1) : 0;
            end
        compute_expected();
        check_result("TEST 6: A x Diagonal (1..N)");

        // ------------------------------------------------------------
        // Summary
        // ------------------------------------------------------------
        $display("\n=============================");
        $display("  RESULTS: %0d passed, %0d failed", tests_passed, tests_failed);
        $display("=============================\n");

        $finish;
    end
endmodule
