
mutable struct Tour
    path::Vector{Int}  # current list of vertices
    length::Float64
    min_contrib::Vector{Float64}  # smallest incoming edge for each vertex (used for lower bound)
    best_known::Union{Nothing, Float64}  # best current solution
    lower::Float64  # lower bound for remaining tour
    finish_time::Float64  # when to timeout

    n::Int  # size of instance

    function Tour(n::Int, timeout::Int)
        return new([1], 0.0, [0.0 for i in 1 : n],nothing, 0.0, time() + timeout, n)
    end
end


"""
    solve_bnb(tsp, timeout)

Solves a TSPLIB instance with the Branch-and-Bound method.

# Arguments
- `tsp`: the TSPLIB instance
- `timeout`: solver timeout in seconds
"""
function solve_bnb(tsp::TSP, timeout::Int=600)
    tour = Tour(size(tsp.weights, 1), timeout)

    for v in 1 : tour.n
        tour.min_contrib[v] = minimum(tsp.weights[:, v])
    end

    tour.lower = sum(tour.min_contrib)  # initialize lower bound as sum over all minimum contributions

    backtrack!(tsp, tour)
end


function backtrack!(tsp::TSP, tour::Tour)
    # hamilton cycle found, check if it has smaller cost
    if length(tour.path) == tour.n
        tour.length += tsp.weights[last(tour.path), tour.path[1]]  # add closing edge

        if isnothing(tour.best_known) || tour.length < tour.best_known
            tour.best_known = tour.length
            println("New Best Solution: $(tour.best_known) for $(tour.path)")
        end

        tour.length -= tsp.weights[last(tour.path), tour.path[1]]  # remove closing edge

        return true
    end

    # backtrack if lower bound for current tour is bigger than best known
    if !isnothing(tour.best_known) && tour.length + tour.lower > tour.best_known
        if time() > tour.finish_time
            println("Timeout with current best solution: $(tour.best_known) for tour $(tour.path)")
            return false
        end

        return true
    end

    available_edges = [(i, tsp.weights[last(tour.path), i]) for i in 1 : tour.n if !(i in tour.path)]  # (next vertex, edge weight)

    # branch first with shortest edge from current vertex
    for (next, weight) in sort(available_edges, by = x -> x[2])
        # add next to tour
        push!(tour.path, next)
        tour.length += weight
        tour.lower -= tour.min_contrib[next]

        if !backtrack!(tsp, tour)
            return false
        end

        # remove next from tour
        pop!(tour.path)
        tour.length -= weight
        tour.lower += tour.min_contrib[next]
    end

    return true
end