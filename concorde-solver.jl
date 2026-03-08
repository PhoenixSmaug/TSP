# Concorde TSP Solver - CLI Wrapper
# Calls the system-installed Concorde binary directly

"""
    solve_concorde(tsp, timeout)

Solves a TSPLIB instance using the Concorde solver via command-line interface.

This wrapper calls the Concorde binary directly, avoiding the need for the
Concorde.jl package to build its own copy.

Requires: Concorde binary installed (e.g., at ~/.local/bin/concorde)

# Arguments
- `tsp`: the TSPLIB instance (from TSPLIB.jl)
- `timeout`: solver timeout in seconds
"""
function solve_concorde(tsp, timeout::Int=60)
  # Find concorde binary
  concorde_path = get(ENV, "CONCORDE_PATH", expanduser("~/.local/bin/concorde"))

  if !isfile(concorde_path)
    # Try to find in PATH
    try
      concorde_path = strip(read(`which concorde`, String))
    catch
      concorde_path = ""
    end
    if isempty(concorde_path) || !isfile(concorde_path)
      println("Concorde binary not found. Install from http://www.math.uwaterloo.ca/tsp/concorde/")
      return nothing, nothing
    end
  end

  n = tsp.dimension

  # Create temporary directory for working files
  mktempdir() do tmpdir
    # Write distance matrix in TSPLIB format
    tsp_file = joinpath(tmpdir, "problem.tsp")
    sol_file = joinpath(tmpdir, "problem.sol")

    open(tsp_file, "w") do f
      println(f, "NAME: problem")
      println(f, "TYPE: TSP")
      println(f, "DIMENSION: $n")
      println(f, "EDGE_WEIGHT_TYPE: EXPLICIT")
      println(f, "EDGE_WEIGHT_FORMAT: FULL_MATRIX")
      println(f, "EDGE_WEIGHT_SECTION")

      for i in 1:n
        row = String[]
        for j in 1:n
          push!(row, string(round(Int, tsp.weights[i, j])))
        end
        println(f, join(row, " "))
      end
      println(f, "EOF")
    end

    try
      # Run concorde FROM the temp directory so it writes files there
      # Use -x to clean up intermediate files
      cmd = Cmd(`$concorde_path -x -o problem.sol problem.tsp`, dir=tmpdir)

      t_start = time()
      proc = run(pipeline(cmd, stdout=devnull, stderr=devnull), wait=false)

      deadline = time() + timeout
      while process_running(proc) && time() < deadline
        sleep(0.1)
      end

      if process_running(proc)
        kill(proc)
        return nothing, nothing
      end

      elapsed = time() - t_start

      if !isfile(sol_file)
        println("Concorde did not produce a solution file")
        return nothing, nothing
      end

      # Parse solution file to get tour
      lines = readlines(sol_file)
      if isempty(lines)
        return nothing, nothing
      end

      # First line is the number of nodes
      # Remaining lines contain the tour (0-indexed node indices)
      tour_nodes = Int[]
      for line in lines[2:end]
        for s in split(strip(line))
          push!(tour_nodes, parse(Int, s) + 1)  # Convert to 1-indexed
        end
      end

      # Calculate tour cost
      if length(tour_nodes) >= n
        cost = 0.0
        for i in 1:n
          from = tour_nodes[i]
          to = tour_nodes[mod1(i + 1, n)]
          cost += tsp.weights[from, to]
        end
        return cost, elapsed
      else
        return nothing, nothing
      end

    catch e
      println("Concorde error: $e")
      return nothing, nothing
    end
  end
end
