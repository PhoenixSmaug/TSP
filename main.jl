# TSP Solver Benchmark Suite
# Includes: Exact methods, Heuristics, and Metaheuristics

using TSPLIB
using Statistics

# Exact solvers
include("integer-programming.jl")
include("branch-and-bound.jl")
include("dynamic-programming.jl")

# External near-optimal solvers
include("lkh-solver.jl")        # Requires: Pkg.add("LKH") + LKH binary
include("concorde-solver.jl")   # Requires: Pkg.add("Concorde") + Concorde binary
include("hygese-solver.jl")     # Requires: Pkg.add("Hygese")

# Classical heuristics
include("heuristics-solver.jl") # Requires: Pkg.add("TravelingSalesmanHeuristics")

# Genetic Algorithm / Metaheuristics
include("genetic-algorithm.jl")   # Requires: Pkg.add("Metaheuristics")

# header parsing inconsistent and TSP constructor fails for large instances like pla85900.tsp, so simply count vertices by line
function get_instance_size(path::String)
    count = 0
    open(path) do file
        for line in eachline(file)
            if occursin(r"^\s*\d", line)
                count += 1
            end
        end
    end
    return count
end

function get_small_instances(limit::Int=25)
    tsp_files = filter(file -> endswith(file, ".tsp"), readdir(TSPLIB.TSPLIB95_path, join=true))
    small_files = String[]

    for path in tsp_files
        size_est = get_instance_size(path)
        if size_est > 0 && size_est <= limit
            push!(small_files, path)
        end
    end

    return small_files
end

"""
Run a solver with result formatting.
Returns formatted result string.
"""
function run_solver(name::String, solver_fn, tsp, timeout::Int)
    println("Starting $name (timeout $(timeout)s):")
    val, t = solver_fn(tsp, timeout)
    res = (val === nothing) ? "Timeout/Error" : string(round(val, digits=0))
    time_str = (t === nothing) ? "-" : string(round(t, digits=3))
    println("Results: $res ($(time_str)s)")
    return (name=name, value=val, time=t)
end

"""
Main benchmark function with configurable solver selection.
"""
function benchmark(;
    use_bnb::Bool=true,
    use_dp::Bool=true,
    use_ilp::Bool=true,
    use_lkh::Bool=true,
    use_concorde::Bool=true,
    use_hygese::Bool=true,
    use_heuristics::Bool=true,
    use_ga::Bool=true,
    max_size::Int=25,
    timeout::Int=60
)
    files = get_small_instances(max_size)
    total = length(files)

    println("="^60)
    println("TSP Solver Benchmark Suite")
    println("="^60)
    println("Found $total instances with size <= $max_size")
    println("Timeout: $(timeout)s per solver\n")

    all_results = []

    for (i, path) in enumerate(files)
        # Load
        tsp = readTSP(path)
        name = basename(path)

        println("\n" * "="^60)
        println("Instance: $name | Size: $(tsp.dimension) | Optimum: $(tsp.optimal) ($i/$total)")
        println("-"^60)

        instance_results = Dict("instance" => name, "optimal" => tsp.optimal)

        # Exact solvers
        if use_bnb
            r = run_solver("Branch and Bound", solve_bnb, tsp, timeout)
            instance_results["bnb"] = r
        end

        if use_dp
            r = run_solver("Dynamic Programming", solve_dp, tsp, timeout)
            instance_results["dp"] = r
        end

        if use_ilp
            r = run_solver("Integer Linear Programming", solve_ilp, tsp, timeout)
            instance_results["ilp"] = r
        end

        # External solvers (if enabled and available)
        if use_lkh && @isdefined(solve_lkh)
            r = run_solver("LKH", solve_lkh, tsp, timeout)
            instance_results["lkh"] = r
        end

        if use_concorde && @isdefined(solve_concorde)
            r = run_solver("Concorde", solve_concorde, tsp, timeout)
            instance_results["concorde"] = r
        end

        if use_hygese && @isdefined(solve_hygese)
            r = run_solver("Hygese", solve_hygese, tsp, timeout)
            instance_results["hygese"] = r
        end

        # Classical heuristics (if enabled and available)
        if use_heuristics
            if @isdefined(solve_nearest_neighbor)
                r = run_solver("Nearest Neighbor", solve_nearest_neighbor, tsp, timeout)
                instance_results["nn"] = r
            end

            if @isdefined(solve_2opt)
                r = run_solver("2-Opt", solve_2opt, tsp, timeout)
                instance_results["2opt"] = r
            end

            if @isdefined(solve_simulated_annealing)
                r = run_solver("Simulated Annealing", solve_simulated_annealing, tsp, timeout)
                instance_results["sa"] = r
            end

            if @isdefined(solve_cheapest_insertion)
                r = run_solver("Cheapest Insertion", solve_cheapest_insertion, tsp, timeout)
                instance_results["ci"] = r
            end
        end

        # Genetic Algorithm
        if use_ga && @isdefined(solve_genetic_algorithm)
            r = run_solver("Genetic Algorithm", solve_genetic_algorithm, tsp, timeout)
            instance_results["ga"] = r
        end

        push!(all_results, instance_results)
    end

    println("\n" * "="^60)
    println("Benchmark Complete!")
    println("="^60)

    return all_results
end

"""
Quick test on a single instance.
"""
function test_single(instance_name::String="burma14"; timeout::Int=30)
    tsp_files = filter(file -> endswith(file, ".tsp"), readdir(TSPLIB.TSPLIB95_path, join=true))
    path = filter(f -> occursin(instance_name, lowercase(basename(f))), tsp_files)

    if isempty(path)
        println("Instance '$instance_name' not found. Available: ")
        for f in tsp_files[1:min(10, length(tsp_files))]
            println("  - $(basename(f))")
        end
        return nothing
    end

    tsp = readTSP(path[1])
    println("Testing on $(basename(path[1])) (n=$(tsp.dimension), optimal=$(tsp.optimal))\n")

    # Test available solvers
    results = []

    # Always available
    push!(results, run_solver("Branch and Bound", solve_bnb, tsp, timeout))
    push!(results, run_solver("Dynamic Programming", solve_dp, tsp, timeout))
    push!(results, run_solver("ILP", solve_ilp, tsp, timeout))

    # GA (should be available)
    if @isdefined(solve_genetic_algorithm)
        push!(results, run_solver("Genetic Algorithm", solve_genetic_algorithm, tsp, timeout))
    end

    # Optional
    @isdefined(solve_lkh) && push!(results, run_solver("LKH", solve_lkh, tsp, timeout))
    @isdefined(solve_concorde) && push!(results, run_solver("Concorde", solve_concorde, tsp, timeout))
    @isdefined(solve_hygese) && push!(results, run_solver("Hygese", solve_hygese, tsp, timeout))
    @isdefined(solve_nearest_neighbor) && push!(results, run_solver("Nearest Neighbor", solve_nearest_neighbor, tsp, timeout))
    @isdefined(solve_2opt) && push!(results, run_solver("2-Opt", solve_2opt, tsp, timeout))
    @isdefined(solve_simulated_annealing) && push!(results, run_solver("Simulated Annealing", solve_simulated_annealing, tsp, timeout))

    return results
end

# Run benchmark by default
benchmark()

# Or test a single instance:
# test_single("burma14")
