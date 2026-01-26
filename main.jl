

using TSPLIB
using Statistics

include("integer-programming.jl")
include("branch-and-bound.jl")
include("dynamic-programming.jl")

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

function benchmark()
    files = get_small_instances(25)
    total = length(files)

    timeout = 60  # seconds
    
    println("Found $total small instances")
    
    for (i, path) in enumerate(files)
        # Load
        tsp = readTSP(path)
        name = basename(path)
        
        println("\nRunning instance $name with optimum $(tsp.optimal) ($i/$total):")
        
        # BnB
        println("Starting Branch and Bound (timeout $(timeout)s):") 
        val_bnb, t_bnb = solve_bnb(tsp, timeout)
        res_bnb = (val_bnb === nothing) ? "Timeout" : string(round(val_bnb, digits=0))
        time_bnb = (t_bnb === nothing) ? "-" : string(round(t_bnb, digits=3))
        println("Results: $res_bnb ($(time_bnb)s)")
        
        # DP
        println("Starting Dynamic Programming (timeout $(timeout)s):")
        val_dp, t_dp = solve_dp(tsp, timeout)
        res_dp = (val_dp === nothing) ? "Timeout" : string(round(val_dp, digits=0))
        time_dp = (t_dp === nothing) ? "-" : string(round(t_dp, digits=3))
        println("Results: $res_dp ($(time_dp)s)")
        
        # ILP
        println("Starting Integer Linear Programming (timeout $(timeout)s):")
        val_ilp, t_ilp = solve_ilp(tsp, timeout)
        res_ilp = (val_ilp === nothing) ? "Timeout" : string(round(val_ilp, digits=0))
        time_ilp = (t_ilp === nothing) ? "-" : string(round(t_ilp, digits=3))
        println("Results: $res_ilp ($(time_ilp)s)")
    end
end

benchmark()