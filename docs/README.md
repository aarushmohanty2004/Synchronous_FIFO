# Synchronous FIFO Design & Verification

## Overview
This project implements and verifies a **Synchronous FIFO (First-In-First-Out)** in Verilog. The FIFO ensures ordered data storage where the first written data is the first read. The design includes full RTL implementation and a self-checking testbench with a golden reference model and scoreboard.

## Features
- Parameterized FIFO (`DATA_WIDTH`, `DEPTH`)
- Synchronous read/write operations (single clock)
- Write and read pointers with wrap-around
- Occupancy counter (`count`)
- Status flags:
  - `wr_full` (FIFO full)
  - `rd_empty` (FIFO empty)
- Safe handling of overflow and underflow conditions

## FIFO Operation
- **Write**: Occurs when `wr_en = 1` and FIFO is not full
- **Read**: Occurs when `rd_en = 1` and FIFO is not empty
- **Simultaneous Read/Write**:
  - Both pointers increment
  - `count` remains unchanged
- **Reset**:
  - Active-low synchronous reset
  - Clears pointers and count

## Verification Strategy
- **Golden Model**:
  - Behavioral FIFO implemented inside testbench
  - Independent of DUT logic
- **Scoreboard**:
  - Compares DUT vs model every cycle:
    - `rd_data`
    - `count`
    - `wr_full`
    - `rd_empty`
- **Automatic Failure Detection**:
  - Prints error details and stops simulation

## Test Cases
- Reset Test
- Single Write/Read
- Fill (Full Condition)
- Drain (Empty Condition)
- Overflow Attempt
- Underflow Attempt
- Simultaneous Read/Write
- Pointer Wrap-Around

## Coverage Metrics
- Full condition hits
- Empty condition hits
- Pointer wrap events
- Simultaneous operations
- Overflow attempts
- Underflow attempts

## Results Discussion
On Simulation using ModelSim 20.1 it was found that:-
- RESET TEST PASSED
- SINGLE TEST PASSED
- FILL TEST PASSED
- DRAIN TEST PASSED
- OVERFLOW TEST PASSED

However, if was found that:-
- SIMULTANEOUS TEST FAILED
- UNDERFLOW TEST FAILED

Therefore,
# ===== COVERAGE =====
- Full        = 5
- Empty       = 6
- Simultaneous= 0
- Overflow    = 2
- Underflow   = 0