using Metaheuristics
using Random

"""
    tour_cost(perm, dist_matrix)

Calculates the total tour length for a given permutation of cities.
"""
function tour_cost(perm::Vector{Int}, dist_matrix::Matrix{Float64})
    n = length(perm)
    cost = 0.0
    for i in 1:n-1
        cost += dist_matrix[perm[i], perm[i+1]]
    end
    cost += dist_matrix[perm[n], perm[1]]
    return cost
end

"""
    order_crossover(parent1, parent2)

Performs Order Crossover (OX) on two parent permutations.

Copies a random segment from parent1 directly, then fills remaining positions with cities from parent2 in order, skipping those already placed. This preserves relative ordering from both parents while ensuring valid permutations.
"""
function order_crossover(parent1::Vector{Int}, parent2::Vector{Int})
    n = length(parent1)

    # Select crossover segment
    cp1, cp2 = sort(rand(1:n, 2))

    child = zeros(Int, n)
    child[cp1:cp2] = parent1[cp1:cp2]

    # Fill remaining from parent2
    pos = cp2 + 1
    for i in 1:n
        idx = ((cp2 + i - 1) % n) + 1
        gene = parent2[idx]
        if !(gene in child)
            if pos > n
                pos = 1
            end
            while child[pos] != 0
                pos = pos % n + 1
            end
            child[pos] = gene
            pos += 1
        end
    end

    return child
end

"""
    swap_mutation!(perm, mutation_rate)

Applies swap mutation to a permutation in-place.

Each position has a probability of mutation_rate to be swapped with another random position. Multiple swaps can occur in a single call.
"""
function swap_mutation!(perm::Vector{Int}, mutation_rate::Float64=0.1)
    n = length(perm)
    for _ in 1:n
        if rand() < mutation_rate
            i, j = rand(1:n, 2)
            perm[i], perm[j] = perm[j], perm[i]
        end
    end
    return perm
end

"""
    two_opt_mutation!(perm, dist_matrix)

Applies 2-opt local search to improve a permutation in-place.

Repeatedly reverses segments that would shorten the tour until no improvement is possible. This is a standard local search for TSP that helps refine GA solutions.
"""
function two_opt_mutation!(perm::Vector{Int}, dist_matrix::Matrix{Float64})
    n = length(perm)
    improved = true

    while improved
        improved = false
        for i in 1:n-1
            for j in i+2:n
                if j == n && i == 1
                    continue
                end

                # Calculate change in distance
                i1, i2 = perm[i], perm[i+1]
                j1, j2 = perm[j], perm[j%n+1]

                delta = dist_matrix[i1, j1] + dist_matrix[i2, j2] -
                        dist_matrix[i1, i2] - dist_matrix[j1, j2]

                if delta < -1e-10
                    perm[i+1:j] = reverse(perm[i+1:j])
                    improved = true
                end
            end
        end
    end
    return perm
end

"""
    solve_genetic_algorithm(tsp, timeout; pop_size, generations, mutation_rate, elite_ratio, local_search)

Solves a TSPLIB instance using a custom Genetic Algorithm.

Implements a steady-state GA with tournament selection, Order Crossover (OX), swap mutation, and optional 2-opt local search. Elitism preserves the best individuals across generations. The combination of global search (GA) with local improvement (2-opt) is a memetic algorithm approach that often outperforms pure genetic search.

# Arguments
- `tsp`: the TSPLIB instance
- `timeout`: solver timeout in seconds
- `pop_size`: population size (default: 100)
- `generations`: maximum generations (default: 500)
- `mutation_rate`: probability of swap mutation per position (default: 0.1)
- `elite_ratio`: fraction of population preserved as elite (default: 0.1)
- `local_search`: whether to apply 2-opt to some offspring (default: true)
"""
function solve_genetic_algorithm(tsp, timeout::Int=60;
    pop_size::Int=100,
    generations::Int=500,
    mutation_rate::Float64=0.1,
    elite_ratio::Float64=0.1,
    local_search::Bool=true)
    n = tsp.dimension
    dist_matrix = Float64.(tsp.weights)

    t_start = time()

    try
        # Initialize population with random permutations
        population = [shuffle(1:n) |> collect for _ in 1:pop_size]
        fitness = [tour_cost(ind, dist_matrix) for ind in population]

        best_cost = minimum(fitness)
        best_tour = population[argmin(fitness)]

        n_elite = max(1, round(Int, pop_size * elite_ratio))

        for gen in 1:generations
            if time() - t_start > timeout
                break
            end

            # Sort by fitness (lower is better)
            sorted_idx = sortperm(fitness)
            population = population[sorted_idx]
            fitness = fitness[sorted_idx]

            # Update best
            if fitness[1] < best_cost
                best_cost = fitness[1]
                best_tour = copy(population[1])
            end

            # Create new population
            new_population = Vector{Vector{Int}}(undef, pop_size)
            new_fitness = Vector{Float64}(undef, pop_size)

            # Elitism
            for i in 1:n_elite
                new_population[i] = copy(population[i])
                new_fitness[i] = fitness[i]
            end

            # Generate offspring
            for i in n_elite+1:pop_size
                # Tournament selection
                t1, t2 = rand(1:pop_size, 2), rand(1:pop_size, 2)
                p1 = population[t1[fitness[t1[1]] < fitness[t1[2]] ? 1 : 2]]
                p2 = population[t2[fitness[t2[1]] < fitness[t2[2]] ? 1 : 2]]

                child = order_crossover(p1, p2)
                swap_mutation!(child, mutation_rate)

                # Optional local search on some offspring
                if local_search && rand() < 0.1
                    two_opt_mutation!(child, dist_matrix)
                end

                new_population[i] = child
                new_fitness[i] = tour_cost(child, dist_matrix)
            end

            population = new_population
            fitness = new_fitness

            if gen % 100 == 0
                println("  GA gen $gen: best = $(round(best_cost, digits=2))")
            end
        end

        # Final local search on best
        if local_search
            two_opt_mutation!(best_tour, dist_matrix)
            best_cost = tour_cost(best_tour, dist_matrix)
        end

        elapsed = time() - t_start
        return best_cost, elapsed

    catch e
        println("Genetic Algorithm error: $e")
        return nothing, nothing
    end
end

"""
    solve_metaheuristics_eca(tsp, timeout)

Solves a TSPLIB instance using ECA (Evolutionary Centers Algorithm) from Metaheuristics.jl.

Uses a continuous-to-permutation decoding: the optimizer searches in continuous n-dimensional space, and solutions are decoded to permutations via argsort. This is an alternative approach when direct permutation operators are not available.

# Arguments
- `tsp`: the TSPLIB instance
- `timeout`: solver timeout in seconds
"""
function solve_metaheuristics_eca(tsp, timeout::Int=60)
    n = tsp.dimension
    dist_matrix = Float64.(tsp.weights)

    t_start = time()

    try
        # Decode continuous vector to permutation via sorting
        function objective(x)
            perm = sortperm(x)
            return tour_cost(perm, dist_matrix)
        end

        bounds = BoxConstrainedSpace(lb=zeros(n), ub=ones(n))

        result = optimize(objective, bounds, ECA(N=50, K=3);
            options=Options(time_limit=Float64(timeout)))

        best_perm = sortperm(minimizer(result))
        best_cost = tour_cost(best_perm, dist_matrix)

        elapsed = time() - t_start
        return best_cost, elapsed

    catch e
        println("Metaheuristics ECA error: $e")
        return nothing, nothing
    end
end
