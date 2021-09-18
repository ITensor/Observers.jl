# Observer.jl

The Observes.jl package provides functionalities to record and track metrics of interests during the iterative evaluation
of a given function. It may be used to monitor convergence of optimization algorithms, to measure revelant observables in
in numerical simulations (e.g. condensed matter physics, quantum simulation, quantum chemistry etc).

```julia
using Observers

# Series for π/4
f(k) = (-1)^(k+1)/(2k-1)

function my_iterative_function(niter; observer!, observe_step)
  π_approx = 0.0
  for n in 1:niter
    π_approx += f(n)
    if iszero(n % observe_step)
      update!(observer!; π_approx = 4π_approx, iteration = n)
    end
  end
  return 4π_approx
end

# Measure the relative error from π at each iteration
err_from_π(; π_approx, kwargs...) = abs(π - π_approx) / π

# Record which iteration we are at
iteration(; iteration, kwargs...) = iteration
obs = Observer(["Error" => err_from_π, "Iteration" => iteration])

niter = 10000
π_approx = my_iterative_function(niter; observer! = obs, observe_step = 1000)

@show obs
# obs = Observer(
#   "Iteration" => NamedTuple{(:f, :results), Tuple{Function, Vector{Any}}}
#                  ((iteration, Any[1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000])), 
#   "Error" => NamedTuple{(:f, :results), Tuple{Function, Vector{Any}}}
#              ((err_from_π, Any[0.0003183098066059948, 0.0001591549331452938, 0.00010610329244741256, 7.957747030096378e-5, 6.366197660078155e-5, 
#                                5.305164733068067e-5, 4.54728406537879e-5, 3.978873562176942e-5, 3.536776502730045e-5, 3.18309885415475e-5])))


@show results(obs["Iteration"])
# results(obs, "Iteration") = 
#   Any[1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000]


@show results(obs["Error"])
# results(obs, "Error") = 
#   Any[0.0003183098066059948, 0.0001591549331452938, 0.00010610329244741256, 7.957747030096378e-5, 6.366197660078155e-5, 
#       5.305164733068067e-5, 4.54728406537879e-5, 3.978873562176942e-5, 3.536776502730045e-5, 3.18309885415475e-5]
```
