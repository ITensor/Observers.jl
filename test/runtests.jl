using Observers
using Test

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

@test length(obs) == 2
@test results(obs, "Error") == []
@test results(obs, "Iteration") == []

niter = 10000
observe_step = 1000
π_approx = my_iterative_function(niter; observer! = obs, observe_step = observe_step)

for res in obs
  @test length(last(last(res))) == niter ÷ observe_step
end

save("outputdata.jld", obs)

obs_load = load("outputdata.jld")

for (k,v) in obs_load
  @test v ≈ last(obs[k])
end
