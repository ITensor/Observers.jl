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
iteration(; iteration, kwargs...) = iteration
obs = observer(iteration, error)

niter = 10000
π_approx = my_iterative_function(niter; (observer!)=obs, observe_step=1000)

@show π_approx
@show obs
@show obs.iteration
@show obs.error
