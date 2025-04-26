# Various solvers for the Travelling Salesman Problem

The [Travelling Salesman Problem (TSP)](https://en.m.wikipedia.org/wiki/Travelling_salesman_problem) is a famously hard combinatorial optimization problem. Here two solvers are implemented:

* An efficient solver, which uses the [Miller-Tucker-Zemlin Encoding](https://phabe.ch/2021/09/19/tsp-subtour-elimination-by-miller-tucker-zemlin-constraint/) to translate TSP into an Integer Programming problem and solves that with the commercial state-of-the-art solver Gurobi
* A simple branch-and-bound solver for educational purposes, who can prune backtracking branches as soon as their lower bound is bigger than the current maximum

Using `benchmark()`, one can compare the performances on the [TSPLIB95 Dataset](http://comopt.ifi.uni-heidelberg.de/software/TSPLIB95/).

(c) Mia Müßig
