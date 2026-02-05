# Classical TSP Heuristics wrapper
# Uses the TravelingSalesmanHeuristics.jl package

import TravelingSalesmanHeuristics as TSH

"""
    solve_nearest_neighbor(tsp, timeout)

Solves a TSPLIB instance using the Nearest Neighbor heuristic.

Starting from an arbitrary city, repeatedly visits the nearest unvisited city
until all cities are visited. Simple and fast O(n^2), but typically produces
tours longer than optimal.

# Arguments
- `tsp`: the TSPLIB instance
- `timeout`: solver timeout in seconds
"""
function solve_nearest_neighbor(tsp, timeout::Int=60)
    dist_matrix = Float64.(tsp.weights)

    t_start = time()

    try
        tour, cost = TSH.nearest_neighbor(dist_matrix)
        elapsed = time() - t_start
        return cost, elapsed
    catch e
        println("Nearest Neighbor error: $e")
        return nothing, nothing
    end
end

"""
    solve_2opt(tsp, timeout)

Solves a TSPLIB instance using 2-opt local search.

The 2-opt algorithm iteratively removes two edges and reconnects the tour in
the only other possible way, accepting improvements until no beneficial swap
remains. Starting from a Nearest Neighbor tour, this typically reduces tour
length by 5-10%.

# Arguments
- `tsp`: the TSPLIB instance
- `timeout`: solver timeout in seconds
"""
function solve_2opt(tsp, timeout::Int=60)
    dist_matrix = Float64.(tsp.weights)

    t_start = time()

    try
        # Initialize with nearest neighbor, then improve
        init_tour, _ = TSH.nearest_neighbor(dist_matrix)
        tour, cost = TSH.two_opt(dist_matrix, init_tour)
        elapsed = time() - t_start
        return cost, elapsed
    catch e
        println("2-opt error: $e")
        return nothing, nothing
    end
end

"""
    solve_simulated_annealing(tsp, timeout)

Solves a TSPLIB instance using Simulated Annealing.

Simulated Annealing is a probabilistic metaheuristic that allows uphill moves
with decreasing probability as the "temperature" cools. This helps escape local
optima that trap greedy methods like 2-opt.

# Arguments
- `tsp`: the TSPLIB instance
- `timeout`: solver timeout in seconds
"""
function solve_simulated_annealing(tsp, timeout::Int=60)
    dist_matrix = Float64.(tsp.weights)

    t_start = time()

    try
        # Simulated annealing takes only the distance matrix
        tour, cost = TSH.simulated_annealing(dist_matrix)
        elapsed = time() - t_start
        return cost, elapsed
    catch e
        println("Simulated Annealing error: $e")
        return nothing, nothing
    end
end

"""
    solve_cheapest_insertion(tsp, timeout)

Solves a TSPLIB instance using the Cheapest Insertion heuristic.

Builds a tour incrementally by repeatedly inserting the city that increases
tour length the least. Starts with a small triangle and grows until all cities
are included.

# Arguments
- `tsp`: the TSPLIB instance
- `timeout`: solver timeout in seconds
"""
function solve_cheapest_insertion(tsp, timeout::Int=60)
    dist_matrix = Float64.(tsp.weights)

    t_start = time()

    try
        tour, cost = TSH.cheapest_insertion(dist_matrix)
        elapsed = time() - t_start
        return cost, elapsed
    catch e
        println("Cheapest Insertion error: $e")
        return nothing, nothing
    end
end
