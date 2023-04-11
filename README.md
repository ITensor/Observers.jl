[![Tests](https://github.com/GTorlai/Observers.jl/workflows/Tests/badge.svg)](https://github.com/GTorlai/Observers.jl/actions?query=workflow%3ATests)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)



# Observers.jl



The Observers.jl package provides functionalities to record and track metrics of interest during the iterative evaluation
of a given function. It may be used to monitor convergence of optimization algorithms, to measure revelant observables in
in numerical simulations (e.g. condensed matter physics, quantum simulation, quantum chemistry etc).



## News



Observers.jl v0.1 has been released, which preserves the same basic constructor
and `update!` interface but a new design of the `Observer` type, which now
has the interface and functionality of a `DataFrame` from
[DataFrames.jl](https://dataframes.juliadata.org/stable/). See the rest of
this [README](https://github.com/GTorlai/Observers.jl#readme), the [examples/](https://github.com/GTorlai/Observers.jl/tree/main/examples)
and [test/](https://github.com/GTorlai/Observers.jl/tree/main/test) directories, and
the [DataFrames.jl documentation](https://dataframes.juliadata.org/stable/)
to learn about how to use the new `Observer` type.



## Installation



You can install this package through the Julia package manager:
```julia
julia> ] add Observers
```



## Basic Usage

```julia
using Observers

# Series for π/4
f(k) = (-1)^(k + 1) / (2k - 1)

function my_iterative_function(niter; observer!, observe_step)
  π_approx = 0.0
  for n in 1:niter
    π_approx += f(n)
    if iszero(n % observe_step)
      update!(observer!; iteration=n, π_approx=4π_approx)
    end
  end
  return 4π_approx
end

# Record the iteration
iteration(; iteration) = iteration

# Measure the relative error from π at each iteration
error(; π_approx) = abs(π - π_approx) / π

obs = Observer(iteration, error)

niter = 10000
```



Now we run the function and analyze the results:

```julia
julia> π_approx = my_iterative_function(niter; (observer!)=obs, observe_step=1000)
3.1414926535900345
```


Results will be saved in the `Observer`, which should act just like a `DataFrame` from the Julia
package [DataFrames.jl](https://dataframes.juliadata.org/stable/). You can view the results
as a table of data by printing it:

```julia
julia> obs
10×2 Observer
 Row │ iteration  error
     │ Int64      Float64
─────┼────────────────────────
   1 │      1000  0.00031831
   2 │      2000  0.000159155
   3 │      3000  0.000106103
   4 │      4000  7.95775e-5
   5 │      5000  6.3662e-5
   6 │      6000  5.30516e-5
   7 │      7000  4.54728e-5
   8 │      8000  3.97887e-5
   9 │      9000  3.53678e-5
  10 │     10000  3.1831e-5
```


Columns store the results from each function that was passed, which can be accessed
in any way that columns of a `DataFrame` can be accessed:

```julia
julia> obs.error
10-element Vector{Float64}:
 0.0003183098066059948
 0.0001591549331452938
 0.00010610329244741256
 7.957747030096378e-5
 6.366197660078155e-5
 5.305164733068067e-5
 4.54728406537879e-5
 3.978873562176942e-5
 3.536776502730045e-5
 3.18309885415475e-5

julia> obs[!, "error"] == obs.error # DataFrames view access syntax
true

julia> obs[!, :error] == obs.error # Can use Symbols
true

julia> obs[:, "error"] == obs.error # Copy the column
true

julia> obs[:, :error] == obs.error # Can use Symbols
true

julia> obs[!, string(error)] == obs.error # Access using function
true

julia> obs[!, Symbol(error)] == obs.error # Access using function
true
```


You can perform various operations on an `Observer` like slicing:

```julia
julia> obs[4:6, :]
3×2 DataFrame
 Row │ iteration  error
     │ Int64      Float64
─────┼───────────────────────
   1 │      4000  7.95775e-5
   2 │      5000  6.3662e-5
   3 │      6000  5.30516e-5
```


See the [DataFrames.jl documentation](https://dataframes.juliadata.org/stable/)
documentation for more information on operations you can perform,
along with the [examples/](https://github.com/GTorlai/Observers.jl/tree/main/examples) and
[test/](https://github.com/GTorlai/Observers.jl/tree/main/test) directory.
You will have to load DataFrames.jl with `using DataFrames` to access DataFrame
functions.
If you find functionality that is available for a `DataFrame` that doesn't work
for an `Observer`, please let us know by raising an issue! You can always convert
an `Observer` to a `DataFrame` in the meantime:

```julia
julia> using DataFrames

julia> df = DataFrame(obs)
10×2 DataFrame
 Row │ iteration  error
     │ Int64      Float64
─────┼────────────────────────
   1 │      1000  0.00031831
   2 │      2000  0.000159155
   3 │      3000  0.000106103
   4 │      4000  7.95775e-5
   5 │      5000  6.3662e-5
   6 │      6000  5.30516e-5
   7 │      7000  4.54728e-5
   8 │      8000  3.97887e-5
   9 │      9000  3.53678e-5
  10 │     10000  3.1831e-5

julia> df.error
10-element Vector{Float64}:
 0.0003183098066059948
 0.0001591549331452938
 0.00010610329244741256
 7.957747030096378e-5
 6.366197660078155e-5
 5.305164733068067e-5
 4.54728406537879e-5
 3.978873562176942e-5
 3.536776502730045e-5
 3.18309885415475e-5

julia> df[4:6, :]
3×2 DataFrame
 Row │ iteration  error
     │ Int64      Float64
─────┼───────────────────────
   1 │      4000  7.95775e-5
   2 │      5000  6.3662e-5
   3 │      6000  5.30516e-5
```


## Custom column names



Alternatively, you can pass string names with the functions which will become
the names of the columns of the Observer:

```julia
julia> obs = Observer("Iteration" => iteration, "Error" => error)
0×2 Observer
 Row │ Iteration  Error
     │ Union{}    Union{}
─────┴────────────────────
```


in which case the results can be accessed from the given specified name:

```julia
julia> obs.Error
Union{}[]

julia> obs.Iteration
Union{}[]
```


This is particularly useful if you pass anonymous function into the `Observer`,
in which case the automatically generated name of the column would be randomly generated.
For example:

```julia
julia> obs = Observer((; iteration) -> iteration, (; π_approx) -> abs(π - π_approx) / π)
0×2 Observer
 Row │ #4       #6
     │ Union{}  Union{}
─────┴──────────────────

julia> π_approx = my_iterative_function(niter; (observer!)=obs, observe_step=1000)
3.1414926535900345

julia> obs
10×2 Observer
 Row │ #4     #6
     │ Int64  Float64
─────┼────────────────────
   1 │  1000  0.00031831
   2 │  2000  0.000159155
   3 │  3000  0.000106103
   4 │  4000  7.95775e-5
   5 │  5000  6.3662e-5
   6 │  6000  5.30516e-5
   7 │  7000  4.54728e-5
   8 │  8000  3.97887e-5
   9 │  9000  3.53678e-5
  10 │ 10000  3.1831e-5
```


You can see that the names of the functions are automatically generated by Julia, since they are
[anonymous functions](https://docs.julialang.org/en/v1/manual/functions/#man-anonymous-functions).



This will make the results harder to access by name, but you can still use
positional information since the columns are ordered based on how
the Observer was defined:

```julia
julia> obs[!, 1]
10-element Vector{Int64}:
  1000
  2000
  3000
  4000
  5000
  6000
  7000
  8000
  9000
 10000

julia> obs[!, 2]
10-element Vector{Float64}:
 0.0003183098066059948
 0.0001591549331452938
 0.00010610329244741256
 7.957747030096378e-5
 6.366197660078155e-5
 5.305164733068067e-5
 4.54728406537879e-5
 3.978873562176942e-5
 3.536776502730045e-5
 3.18309885415475e-5
```


You could also save the anonymous functions in variables and use
them to access the results:

```julia
julia> iter = (; iteration) -> iteration
#10 (generic function with 1 method)

julia> err = (; π_approx) -> abs(π - π_approx) / π
#13 (generic function with 1 method)

julia> obs = Observer(iter, err)
0×2 Observer
 Row │ #10      #13
     │ Union{}  Union{}
─────┴──────────────────

julia> π_approx = my_iterative_function(niter; (observer!)=obs, observe_step=1000)
3.1414926535900345

julia> obs
10×2 Observer
 Row │ #10    #13
     │ Int64  Float64
─────┼────────────────────
   1 │  1000  0.00031831
   2 │  2000  0.000159155
   3 │  3000  0.000106103
   4 │  4000  7.95775e-5
   5 │  5000  6.3662e-5
   6 │  6000  5.30516e-5
   7 │  7000  4.54728e-5
   8 │  8000  3.97887e-5
   9 │  9000  3.53678e-5
  10 │ 10000  3.1831e-5
```


Then, you can use the variables that the functions were stored in to obtain the results:

```julia
julia> obs[!, string(iter)]
10-element Vector{Int64}:
  1000
  2000
  3000
  4000
  5000
  6000
  7000
  8000
  9000
 10000

julia> obs[!, string(err)]
10-element Vector{Float64}:
 0.0003183098066059948
 0.0001591549331452938
 0.00010610329244741256
 7.957747030096378e-5
 6.366197660078155e-5
 5.305164733068067e-5
 4.54728406537879e-5
 3.978873562176942e-5
 3.536776502730045e-5
 3.18309885415475e-5
```


You can also rename the columns to more desirable names:

```julia
julia> rename!(obs, ["Iteration", "Error"])
10×2 Observer
 Row │ Iteration  Error
     │ Int64      Float64
─────┼────────────────────────
   1 │      1000  0.00031831
   2 │      2000  0.000159155
   3 │      3000  0.000106103
   4 │      4000  7.95775e-5
   5 │      5000  6.3662e-5
   6 │      6000  5.30516e-5
   7 │      7000  4.54728e-5
   8 │      8000  3.97887e-5
   9 │      9000  3.53678e-5
  10 │     10000  3.1831e-5

julia> obs.Iteration
10-element Vector{Int64}:
  1000
  2000
  3000
  4000
  5000
  6000
  7000
  8000
  9000
 10000

julia> obs.Error
10-element Vector{Float64}:
 0.0003183098066059948
 0.0001591549331452938
 0.00010610329244741256
 7.957747030096378e-5
 6.366197660078155e-5
 5.305164733068067e-5
 4.54728406537879e-5
 3.978873562176942e-5
 3.536776502730045e-5
 3.18309885415475e-5
```


## Accessing and modifying functions



You can access and modify functions of an Observer with `get_function`, `set_function!`, and `insert_function!`:

```julia
julia> get_function(obs, "Iteration") == iter
true

julia> get_function(obs, "Error") == err
true

julia> set_function!(obs, "Error" => sin);

julia> get_function(obs, "Error") == sin
true

julia> insert_function!(obs, "New column" => cos);

julia> get_function(obs, "New column") == cos
true

julia> obs
10×3 Observer
 Row │ Iteration  Error        New column
     │ Int64      Float64      Missing
─────┼────────────────────────────────────
   1 │      1000  0.00031831      missing
   2 │      2000  0.000159155     missing
   3 │      3000  0.000106103     missing
   4 │      4000  7.95775e-5      missing
   5 │      5000  6.3662e-5       missing
   6 │      6000  5.30516e-5      missing
   7 │      7000  4.54728e-5      missing
   8 │      8000  3.97887e-5      missing
   9 │      9000  3.53678e-5      missing
  10 │     10000  3.1831e-5       missing
```


`set_function!` just updates the function of an existing column but doesn't create new columns,
while `insert_function!` creates a new column and sets the function of that new column
but won't update an existing column.
For example, these will both throw errors:
```julia
set_function!(obs, "New column 2", cos)
insert_function!(obs, "Error", cos)
```



Alternatively, if you define the `Observer` with column names to begin with,
then you can get the results using the function names:

```julia
julia> obs = Observer(
         "Iteration" => (; iteration) -> iteration,
         "Error" => (; π_approx) -> abs(π - π_approx) / π,
       )
0×2 Observer
 Row │ Iteration  Error
     │ Union{}    Union{}
─────┴────────────────────

julia> π_approx = my_iterative_function(niter; (observer!)=obs, observe_step=1000)
3.1414926535900345

julia> obs.Iteration
10-element Vector{Int64}:
  1000
  2000
  3000
  4000
  5000
  6000
  7000
  8000
  9000
 10000

julia> obs.Error
10-element Vector{Float64}:
 0.0003183098066059948
 0.0001591549331452938
 0.00010610329244741256
 7.957747030096378e-5
 6.366197660078155e-5
 5.305164733068067e-5
 4.54728406537879e-5
 3.978873562176942e-5
 3.536776502730045e-5
 3.18309885415475e-5
```


## Reading and Writing to Disk



You can save and load Observers with packages like [JLD2.jl](https://github.com/JuliaIO/JLD2.jl),
or any other packages you like:

```julia
using JLD2
jldsave("results.jld2"; obs)
obs_loaded = Observer(load("results.jld2", "obs"))
```


```julia
julia> obs_loaded == obs
true

julia> obs_loaded.Error == obs.Error
true
```


Another option is saving and loading as a
[CSV file](https://dataframes.juliadata.org/stable/man/importing_and_exporting/#CSV-Files),
though this will drop information about the functions associated with each column:

```julia
using CSV
CSV.write("results.csv", obs)
obs_loaded = Observer(CSV.File("results.csv"))
```


```julia
julia> obs_loaded == obs
true

julia> obs_loaded.Error == obs.Error
true
```


## Generating this README



This [README](https://github.com/GTorlai/Observers.jl#readme) file was generated with
[Weave.jl](https://github.com/JunoLab/Weave.jl) with the following commands:

```julia
using Observers, Weave
weave(
  joinpath(pkgdir(Observers), "examples", "README.jl");
  doctype="github",
  out_path=pkgdir(Observers),
)
```
