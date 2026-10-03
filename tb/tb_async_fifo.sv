`timescale 1ns / 1ps

module tb_async_fifo;

    // Parameters
    parameter DSIZE = 8;
    parameter ASIZE = 4;
    localparam FIFO_DEPTH = 1 << ASIZE; // 16 entries

    // Clocks and Resets
    reg wclk;
    reg wrst_n;
    reg rclk;
    reg rrst_n;

    // Write Interface
    reg              winc;
    reg  [DSIZE-1:0] wdata;
    wire             wfull;

    // Read Interface
    reg              rinc;
    wire [DSIZE-1:0] rdata;
    wire             rempty;

    // Golden Model Reference Queue for Self-Checking
    reg [DSIZE-1:0] expected_queue [$];
    integer error_count = 0;
    integer items_written = 0;
    integer items_read = 0;
    integer i;

    // -------------------------------------------------------------
    // Device Under Test (DUT) Instantiation
    // -------------------------------------------------------------
    async_fifo #(
        .DSIZE(DSIZE),
        .ASIZE(ASIZE)
    ) dut (
        .wclk   (wclk),
        .wrst_n (wrst_n),
        .winc   (winc),
        .wdata  (wdata),
        .wfull  (wfull),
        .rclk   (rclk),
        .rrst_n (rrst_n),
        .rinc   (rinc),
        .rdata  (rdata),
        .rempty (rempty)
    );

    // -------------------------------------------------------------
    // Clock Generation
    // -------------------------------------------------------------
    initial begin
        wclk = 0;
        forever #5 wclk = ~wclk;   // 100 MHz (10ns period)
    end

    initial begin
        rclk = 0;
        forever #12 rclk = ~rclk; // ~41.6 MHz (24ns period)
    end

    // -------------------------------------------------------------
    // Task: Reset Initialization
    // -------------------------------------------------------------
    task reset_system;
        begin
            winc   = 0;
            wdata  = 0;
            rinc   = 0;
            wrst_n = 0;
            rrst_n = 0;

            #50;
            @(posedge wclk);
            wrst_n = 1;
            @(posedge rclk);
            rrst_n = 1;
            #20;
            $display("[TB] --- System Reset Complete ---");
        end
    endtask

    // -------------------------------------------------------------
    // Task: Push Data into FIFO
    // -------------------------------------------------------------
    task write_data(input [DSIZE-1:0] data_in);
        begin
            @(posedge wclk);
            if (!wfull) begin
                winc   = 1'b1;
                wdata  = data_in;
                expected_queue.push_back(data_in);
                items_written = items_written + 1;
                @(posedge wclk);
                winc   = 1'b0;
            end else begin
                $display("[TB WARN] Write attempted while FIFO is FULL! Dropped: 0x%0h", data_in);
                @(posedge wclk);
                winc   = 1'b0;
            end
        end
    endtask

    // -------------------------------------------------------------
    // Task: Pop Data and Compare
    // -------------------------------------------------------------
    task read_data;
        reg [DSIZE-1:0] expected_val;
        begin
            @(posedge rclk);
            if (!rempty) begin
                rinc = 1'b1;
                @(posedge rclk);
                rinc = 1'b0;
                
                if (expected_queue.size() > 0) begin
                    expected_val = expected_queue.pop_front();
                    items_read = items_read + 1;
                    if (rdata !== expected_val) begin
                        $display("[TB ERROR] Mismatch! Read: 0x%0h | Expected: 0x%0h at time %0t", rdata, expected_val, $time);
                        error_count = error_count + 1;
                    end else begin
                        $display("[TB PASS] Matched: 0x%0h", rdata);
                    end
                end
            end else begin
                $display("[TB WARN] Read attempted while FIFO is EMPTY!");
                @(posedge rclk);
                rinc = 1'b0;
            end
        end
    endtask

    // -------------------------------------------------------------
    // Main Stimulus Sequence
    // -------------------------------------------------------------
    initial begin
        reset_system();

        // 1. Fill FIFO until Full
        $display("\n[TB] === TEST 1: Filling FIFO to Capacity ===");
        for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
            write_data($random & 8'hFF);
        end

        repeat (3) @(posedge wclk);

        if (wfull) begin
            $display("[TB PASS] FIFO asserted FULL flag.");
        end else begin
            $display("[TB FAIL] FIFO did NOT assert FULL flag!");
            error_count = error_count + 1;
        end

        // 2. Illegal Write on Full
        $display("\n[TB] === TEST 2: Testing Overflow Protection ===");
        write_data(8'hAA);

        // 3. Drain FIFO to Empty
        $display("\n[TB] === TEST 3: Draining FIFO to Empty ===");
        while (!rempty) begin
            read_data();
        end

        repeat (3) @(posedge rclk);

        if (rempty) begin
            $display("[TB PASS] FIFO asserted EMPTY flag.");
        end else begin
            $display("[TB FAIL] FIFO did NOT assert EMPTY flag!");
            error_count = error_count + 1;
        end

        // 4. Concurrent Randomized Operations
        $display("\n[TB] === TEST 4: Concurrent Operations ===");
        fork
            begin : write_thread
                integer w_iter;
                for (w_iter = 0; w_iter < 40; w_iter = w_iter + 1) begin
                    @(posedge wclk);
                    if (!wfull && ($random % 2 == 0)) begin
                        write_data($random & 8'hFF);
                    end
                end
            end

            begin : read_thread
                integer r_iter;
                for (r_iter = 0; r_iter < 60; r_iter = r_iter + 1) begin
                    @(posedge rclk);
                    if (!rempty && ($random % 2 == 0)) begin
                        read_data();
                    end
                end
            end
        join

        // Drain remaining data
        $display("\n[TB] Draining remaining entries...");
        while (expected_queue.size() > 0) begin
            read_data();
        end

        // Summary
        #100;
        $display("\n==============================================");
        $display("              SIMULATION SUMMARY              ");
        $display("==============================================");
        $display(" Total Items Written : %0d", items_written);
        $display(" Total Items Read    : %0d", items_read);
        $display(" Total Errors Found  : %0d", error_count);
        if (error_count == 0) begin
            $display(" STATUS: >>> ALL TESTS PASSED SUCCESSFULLY <<<");
        end else begin
            $display(" STATUS: >>> FAILED WITH %0d ERRORS <<<", error_count);
        end
        $display("==============================================\n");

        $finish;
    end

endmodule