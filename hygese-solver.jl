# Hygese TSP Solver wrapper
# Uses the Hygese.jl package (Hybrid Genetic Search)

import Hygese

"""
    solve_hygese(tsp, timeout)

Solves a TSPLIB instance using HGS (Hybrid Genetic Search).

Hygese implements a state-of-the-art hybrid genetic algorithm. The algorithm
combines population-based search with local improvement procedures for high-quality
solutions.

# Arguments
- `tsp`: the TSPLIB instance
- `timeout`: solver timeout in seconds
"""
function solve_hygese(tsp, timeout::Int=60)
  n = tsp.dimension
  dist_matrix = Float64.(tsp.weights)

  t_start = time()

  try
    result = Hygese.solve_tsp(dist_matrix; verbose=false)

    elapsed = time() - t_start
    return result.cost, elapsed
  catch e
    println("Hygese error: $e")
    return nothing, nothing
  end
end
