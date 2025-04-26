
using JuMP
using Gurobi

"""
    solve_ilp(tsp, timeout)

Solves a TSPLIB instance with Integer Programming using the Miller-Tucker-Zemlin encoding.

# Arguments
- `tsp`: the TSPLIB instance
- `timeout`: solver timeout in seconds
"""
function solve_ilp(tsp::TSP, timeout::Int=60)
    model = Model(Gurobi.Optimizer)
    set_time_limit_sec(model, timeout)

    n = size(tsp.weights, 1)

    @variable(model, x[i=1:n, j=1:n], Bin)  # x[i, j] is 1 iff edge (i, j) is part of TSP tour
    @variable(model, y[1:n] >= 0)  # y[i] encodes after hoe many steps vertex i is visited by the TSP tour (can be replaxed to real variable)

    @constraint(model, y[1] == 1)  # start at vertex 1
    @constraint(model, [i=1:n; i != 1], 2 <= y[i] <= n)  # visit all other vertices in n steps
    @constraint(model, [i=1:n, j=1:n; i != 1 && j != 1], y[i] - y[j] + (n-1) * x[i,j] <= n-2)  # subtour elimination since if x[i, j] it becomes y[i] + 1 <= y[j]
    @constraint(model, [i=1:n], sum(x[i, :]) == 1)  # every vertex has one outgoing edge
    @constraint(model, [j=1:n], sum(x[:, j]) == 1)  # every vertex has one incoming edge

    @objective(model, Min, sum(x[i,j] * tsp.weights[i,j] for i=1:n, j=1:n))  # minimize total length

    optimize!(model)

    # timeout
    if termination_status(model) != MOI.OPTIMAL
        return (nothing, nothing)
    end

    return objective_value(model), solve_time(model)
end