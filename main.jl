

using TSPLIB
using Statistics

include("integer-programming.jl")
include("branch-and-bound.jl")

function benchmark()
    # TSPLIB95 benchmark
    tsp_files = filter(file -> endswith(file, ".tsp"), readdir(TSPLIB.TSPLIB95_path, join=true))
    
    # Initialize counters
    total = length(tsp_files)
    timeouts = 0
    correct = 0
    times = Float64[]
    
    # Loop through each file
    for path in tsp_files
        # Read TSP and solve
        tsp = readTSP(path)
        value, time = solve_ilp(tsp)
        
        # Process results
        if value === nothing
            timeouts += 1
        else
            push!(times, time)
            if isapprox(value, tsp.optimal, rtol=1e-5)
                correct += 1
            end
        end
    end
    
    # Calculate statistics
    completed = total - timeouts
    avg_time = isempty(times) ? 0.0 : mean(times)
    max_time = isempty(times) ? 0.0 : maximum(times)
    total_time = sum(times)
    
    # Print summary
    println("TSP Test Summary:")
    println("Total instances: $total")
    println("Correctly solved: $correct/$completed ($(round(correct/completed*100, digits=1))% of completed)")
    println("Timeouts: $timeouts/$total ($(round(timeouts/total*100, digits=1))%)")
    println("Average time: $(round(avg_time, digits=2))s | Max time: $(round(max_time, digits=2))s | Total time: $(round(total_time, digits=2))s")
end

function test()
    tsp = readTSP(TSPLIB.TSPLIB95_path * "/ulysses16.tsp")

    solve_bnb(tsp, 5)
end

test()