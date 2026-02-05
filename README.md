# Various solvers for the Travelling Salesman Problem

The [Travelling Salesman Problem (TSP)](https://en.m.wikipedia.org/wiki/Travelling_salesman_problem) is a famously hard combinatorial optimization problem. Here two solvers are implemented:

* An efficient solver, which uses the [Miller-Tucker-Zemlin Encoding](https://phabe.ch/2021/09/19/tsp-subtour-elimination-by-miller-tucker-zemlin-constraint/) to translate TSP into an Integer Programming problem and solves that with the commercial state-of-the-art solver Gurobi
* A standalone solver which implements the [Held-Karp algorithm](https://en.wikipedia.org/wiki/Held%E2%80%93Karp_algorithm) to solve TSP with dynamic programming
* A simple branch-and-bound solver for educational purposes, who can prune backtracking branches as soon as their lower bound is bigger than the current maximum
* [Concorde](http://www.math.uwaterloo.ca/tsp/concorde.html) State-of-the-art exact TSP solver using cutting planes
* [LKH-3](http://webhotel4.ruc.dk/~keld/research/LKH-3/) Lin-Kernighan Heuristic, one of the best TSP heuristics
* [Hygese](https://github.com/chkwon/Hygese.jl) Hybrid Genetic Search for CVRP/TSP

## Quick Start

```bash
# 1. Run setup (installs all Julia packages)
julia setup.jl

# 2. Run the benchmark
julia --project=. main.jl
```

## Benchmark Results

Using `benchmark()`, solvers are compared on the [TSPLIB95 Dataset](http://comopt.ifi.uni-heidelberg.de/software/TSPLIB95/). See `benchmark.log` for pre-recorded results (Intel i9-10980HK, 32 GB RAM).

## Requirements

- **Julia 1.9+** (tested with 1.12)
- **Concorde binary** (for optimal solutions on larger instances)


Using `benchmark()`, one can compare the performances on the [TSPLIB95 Dataset](http://comopt.ifi.uni-heidelberg.de/software/TSPLIB95/). `benchmark.log` also provides pre-recorded results measured with an Intel i9-10980HK and 32 GB of memory.

(c) Mia Müßig
