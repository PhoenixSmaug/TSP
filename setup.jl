#!/usr/bin/env julia
"""
TSP Solver Setup Script
========================

This script installs all required Julia packages and provides instructions for
installing external binaries (Concorde, LKH).

Run with: julia setup.jl
"""

using Pkg

println("="^60)
println("TSP Solver Suite - Setup Script")
println("="^60)

# Activate the project in the current directory
Pkg.activate(".")

println("\n[*] Installing Julia packages...\n")

# Core dependencies (Concorde is called via CLI, not as a Julia package)
packages = [
  "TSPLIB",                    # TSPLIB instance loader
  "Statistics",                # Basic statistics (stdlib)
  "Random",                    # Random number generation (stdlib)
  "JuMP",                      # Mathematical optimization modeling
  "HiGHS",                     # Open-source linear/integer programming solver
  "LKH",                       # Lin-Kernighan Heuristic wrapper
  "Hygese",                    # HGS-CVRP solver
  "TravelingSalesmanHeuristics", # Classical TSP heuristics
  "Metaheuristics",            # Metaheuristic algorithms
]

for pkg in packages
  println("  [+] Installing $pkg...")
  try
    Pkg.add(pkg)
    println("      [OK] $pkg installed successfully")
  catch e
    println("      [WARN] Failed to install $pkg: $e")
  end
end

println("\n[*] Instantiating project dependencies...")
Pkg.instantiate()

println("\n[*] Building LKH...")
try
  Pkg.build("LKH")
  println("    [OK] LKH built successfully")
catch e
  println("    [WARN] LKH build failed: $e")
  println("    See DEVELOPMENT.md for manual installation instructions")
end

println("\n" * "="^60)
println("External Binary Installation")
println("="^60)

# Check if Concorde is installed
concorde_path = expanduser("~/.local/bin/concorde")
concorde_in_path = try
  !isempty(strip(read(`which concorde`, String)))
catch
  false
end

if isfile(concorde_path) || concorde_in_path
  println("\n[OK] Concorde binary found!")
else
  println("""

[WARN] CONCORDE TSP Solver NOT FOUND
       --------------------------------
       Concorde is required for optimal TSP solutions on larger instances.

       Quick Install (Linux x86_64):
         wget http://www.math.uwaterloo.ca/tsp/concorde/downloads/codes/linux24/concorde.gz
         gunzip concorde.gz
         chmod +x concorde
         mv concorde ~/.local/bin/

       Download page: http://www.math.uwaterloo.ca/tsp/concorde/downloads/downloads.htm
""")
end

println("""

Additional Notes:
-----------------
  * HiGHS (ILP solver) is included via Julia package - no manual install needed
  * For better ILP performance, consider installing Gurobi: Pkg.add("Gurobi") + a Gurobi License
  * LKH.jl automatically downloads and builds LKH-3
""")

println("="^60)
println("[OK] Setup Complete!")
println("="^60)

println("""

Next steps:
1. Test the installation:
   julia --project=. main.jl

2. Run a quick test in Julia REPL:
   julia> include("main.jl")
   julia> test_single("burma14")

3. Run the full benchmark:
   julia> benchmark(use_concorde=true, use_lkh=true)

4. See DEVELOPMENT.md for detailed usage instructions.

""")
