# LKH TSP Solver wrapper
# Uses the LKH.jl package

import LKH

"""
    solve_lkh(tsp, timeout)

Solves a TSPLIB instance using the Lin-Kernighan Heuristic (LKH).

LKH is one of the most effective heuristics for the TSP. It extends the classic
Lin-Kernighan algorithm with additional improvement moves and achieves near-optimal
solutions extremely quickly, often finding optimal tours for instances with thousands
of cities.

# Arguments
- `tsp`: the TSPLIB instance
- `timeout`: solver timeout in seconds
"""
function solve_lkh(tsp, timeout::Int=60)
  n = tsp.dimension

  # Build integer distance matrix
  # slight precision loss, but LKH requires integer weights and I think it's fine
  dist_matrix = zeros(Int, n, n)
  for i in 1:n
    for j in 1:n
      if i != j
        dist_matrix[i, j] = round(Int, tsp.weights[i, j])
      end
    end
  end

  t_start = time()

  try
    tour, cost = LKH.solve_tsp(dist_matrix)
    elapsed = time() - t_start

    return Float64(cost), elapsed
  catch e
    println("LKH error: $e")
    return nothing, nothing
  end
end
