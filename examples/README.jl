#' [![Tests](https://github.com/GTorlai/Observers.jl/workflows/Tests/badge.svg)](https://github.com/GTorlai/Observers.jl/actions?query=workflow%3ATests)
#' [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

#' # Observers.jl

#' The Observers.jl package provides functionalities to record and track metrics of interest during the iterative evaluation
#' of a given function. It may be used to monitor convergence of optimization algorithms, to measure revelant observables in
#' in numerical simulations (e.g. condensed matter physics, quantum simulation, quantum chemistry etc).

#' ## News

#' Observers.jl v0.1 has been released, which preserves the same basic constructor
#' and `update!` interface but a new design of the `Observer` type, which now
#' has the interface and functionality of a `DataFrame` from
#' [DataFrames.jl](https://dataframes.juliadata.org/stable/). See the rest of
#' this README, the examples directory, and the DataFrames.jl documentation
#' to learn about how to use the new `Observer` type.

#' ## Installation

#' You can install this package through the Julia package manager:
#' ```julia
#' julia> ] add Observers
#' ```

#' ## Basic Usage

#+ results="hidden"

using Observers

# Series for π/4
f(k) = (-1)^(k + 1) / (2k - 1)

function my_iterative_function(niter; observer!, observe_step)
  π_approx = 0.0
  for n in 1:niter
    π_approx += f(n)
    if iszero(n % observe_step)
      update!(observer!; π_approx=4π_approx, iteration=n)
    end
  end
  return 4π_approx
end

# Measure the relative error from π at each iteration
error(; π_approx) = abs(π - π_approx) / π

# Record which iteration we are at
iteration(; iteration) = iteration

obs = Observer(error, iteration)

niter = 10000

#' Now we run the function and analyze the results:
#+ term=true
π_approx = my_iterative_function(niter; (observer!)=obs, observe_step=1000)

#' Results will be saved in the `Observer`, which should act just like a `DataFrame` from the Julia
#' package [DataFrames.jl](https://dataframes.juliadata.org/stable/). You can view the results
#' as a table of data by printing it:
#+ term=true
obs

#' Columns store the results from each function that was passed, which can be accessed
#' in any way that columns of a `DataFrame` can be accessed:
#+ term=true
obs.error
obs[!, "error"] == obs.error # DataFrames view access syntax
obs[!, :error] == obs.error # Can use Symbols
obs[:, "error"] == obs.error # Copy the column
obs[:, :error] == obs.error # Can use Symbols
obs[!, string(error)] == obs.error # Access using function
obs[!, Symbol(error)] == obs.error # Access using function

#' You can perform various operations on an `Observer` like slicing:
obs[4:6, :]

#' See the DataFrames.jl documentation for more information on operations you can perform.
#' You will have to load DataFrames.jl with `using DataFrames` to access DataFrame
#' functions.
#' If you find functionality that is available for a `DataFrame` that doesn't work
#' for an `Observer`, please let us know by raising an issue! You can always convert
#' an `Observer` to a `DataFrame` in the meantime:
#+ term=true
using DataFrames
df = DataFrame(obs)
df.error
df[4:6, :]

#' ## Custom column names

#' Alternatively, you can pass string names with the functions which will become
#' the names of the columns of the Observer:
#+
obs = Observer("Iteration" => iteration, "Error" => error)

#' in which case the results can be accessed from the given specified name:
#+ term=true
obs.Error
obs.Iteration

#' This is particularly useful if you pass anonymous function into the `Observer`,
#' in which case the automatically generated name of the column would be randomly generated.
#' For example:
#+ term
obs = Observer((; iteration) -> iteration, (; π_approx) -> abs(π - π_approx) / π)
π_approx = my_iterative_function(niter; (observer!)=obs, observe_step=1000)
obs

#' You can see that the names of the functions are automatically generated by Julia, since they are
#' [anonymous functions](https://docs.julialang.org/en/v1/manual/functions/#man-anonymous-functions).

#' This will make the results harder to access by name, but you can still use
#' positional information since the columns are ordered based on how
#' the Observer was defined:
#+ term=true
obs[!, 1]
obs[!, 2]

#' You could also save the anonymous functions in variables and use
#' them to access the results:
#+ term=true
iter = (; iteration) -> iteration
err = (; π_approx) -> abs(π - π_approx) / π
obs = Observer(err, iter)
π_approx = my_iterative_function(niter; (observer!)=obs, observe_step=1000)
obs

#' Then, you can use the variables that the functions were stored in to obtain the results:
#+ term=true
obs[!, string(iter)]
obs[!, string(err)]

#' You can also rename the columns to more desirable names:
#+ term=true
rename!(obs, ["Iteration", "Error"])
obs.Iteration
obs.Error

#' Alternatively, if you define the `Observer` with column names to begin with,
#' then you can get the results using the function names:
#+ term=true
obs = Observer(
  "Iteration" => (; iteration) -> iteration,
  "Error" => (; π_approx) -> abs(π - π_approx) / π,
)
π_approx = my_iterative_function(niter; (observer!)=obs, observe_step=1000)
obs.Iteration
obs.Error

#' ## Reading and Writing to Disk

#' You can save and load Observers with packages like [JLD2.jl](https://github.com/JuliaIO/JLD2.jl),
#' or any other packages you like:
#+ results="hidden"
using JLD2
jldsave("results.jld2"; obs)
obs_loaded = Observer(load("results.jld2", "obs"))
#+ term=true
obs_loaded == obs
obs_loaded.Error == obs.Error

#' Another option is saving and loading as a
#' [CSV file](https://dataframes.juliadata.org/stable/man/importing_and_exporting/#CSV-Files),
#' though this will drop information about the functions associated with each column:
#+ results="hidden"
using CSV
CSV.write("results.csv", obs)
obs_loaded = Observer(CSV.File("results.csv"))
#+ term=true
obs_loaded == obs
obs_loaded.Error == obs.Error

#' ## Generating this README

#' This file was generated with [Weave.jl](https://github.com/JunoLab/Weave.jl) with the following commands:
#+ eval=false

using Observers, Weave
weave(
  joinpath(pkgdir(Observers), "examples", "README.jl");
  doctype="github",
  out_path=pkgdir(Observers),
)
