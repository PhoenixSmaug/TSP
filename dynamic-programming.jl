"""
    solve_dp(tsp, timeout)

Solves a TSPLIB instance with Dynamic Programming using the Held-Karp algorithm.

The central idea is that if we have a partial tour using some vertices, it is not relevant in which order they were used. So we incrementally add one vertex to all previous solution and only store the smallest length for that subset. Works very elegantly for small instances, but the O(n * 2^n) memory requirement makes it infeasible for larger problems.

# Arguments
- `tsp`: the TSPLIB instance
- `timeout`: solver timeout in seconds
"""
function solve_dp(tsp, timeout::Int=60)
    n = size(tsp.weights, 1)

    t_start = time()
    dist = tsp.weights
    
    # C[mask+1, k] stores min path cost from 1 to k visiting vertices in mask
    # Mask bit i represents vertex i+2 (0-indexed bits for vertices 2..n)
    limit = 1 << (n - 1)
    C = fill(Inf, limit, n)
    
    # Base case: paths 1 -> k, where S = {k}
    for k in 2:n
        mask = 1 << (k - 2)
        C[mask + 1, k] = dist[1, k]
    end
    
    # Organize masks by their size (population count) for correct DP order
    masks_by_size = [Int[] for _ in 1:(n-1)]
    for m in 1:(limit-1)
        push!(masks_by_size[count_ones(m)], m)
    end
    
    # Counter for timeout check
    iterations = 0

    # Iterate through subset sizes s from 2 up to n-1
    for s in 2:(n - 1)
        for mask in masks_by_size[s]
            iterations += 1
            if iterations % 10000 == 0
                if time() - t_start > timeout
                    return (nothing, nothing)
                end
            end

            # Identify vertices present in the current mask
            # (reconstructing set S from the mask bits)
            nodes = Int[]
            for b in 0:(n - 2)
                if ((mask >> b) & 1) == 1
                    push!(nodes, b + 2)
                end
            end
            
            for k in nodes
                prev_mask = mask ⊻ (1 << (k - 2))
                
                # Find min cost to reach a vertex m in S\{k}, then move to k
                best_val = Inf
                for m in nodes
                    if m != k
                        val = C[prev_mask + 1, m] + dist[m, k]
                        if val < best_val
                            best_val = val
                        end
                    end
                end
                C[mask + 1, k] = best_val
            end
        end
    end
    
    # Final step: Complete the tour by returning to vertex 1
    # We look at the full mask (all vertices 2..n visited)
    full_mask = limit - 1
    opt = Inf
    for k in 2:n
        val = C[full_mask + 1, k] + dist[k, 1]
        if val < opt
            opt = val
        end
    end
    
    return opt, time() - t_start
end
