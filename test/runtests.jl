using Observers
using Test
using JLD2

import Observers: update!

@testset "Observer" begin
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
  
  save("outputdata.jld2", results(obs)) 
  obs_load = load("outputdata.jld")
  
  for (k,v) in obs_load
    @test v ≈ last(obs[k])
  end
  
  obs = Observer(["Error" => err_from_π, "Iteration" => iteration])
  obs["nofunction"] = nothing
  
  niter = 10000
  observe_step = 1000
  π_approx = my_iterative_function(niter; observer! = obs, observe_step = observe_step)
  
  @test results(obs,"nofunction") == []
  
  f1(x::Int) = x^2
  f2(x::Int, y::Float64) = x + y
  f3(_,_,t::Tuple) = first(t)
  f4(x::Int; a::Float64) = x * a
  f5(x::Int; a::Float64, b::Float64) = x * a + b
  
  
  function my_other_iterative_function(; observer!)
    k = 2
    x = k
    y = k * √2
    t = (x+2*y,0,0)
    a = y^2
    b = 3.0
    update!(observer!, x, y, t; a = a, b = b)
  end
  
  obs = Observer(["f1" => f1, "f2" => f2, "f3" => f3, "f4" => f4, "f5" => f5])
  
  my_other_iterative_function(; observer! = obs)
  
  @test results(obs,"f1")[1] ≈ 4.0
  @test results(obs,"f2")[1] ≈ 2.0 + 2*√2
  @test results(obs,"f3")[1] ≈ 2.0 + 4*√2 
  @test results(obs,"f4")[1] ≈ 16.0
  @test results(obs,"f5")[1] ≈ 19.0
end

@testset "save only last value" begin
  f(x::Int, y::Float64) = x + y
  g(x::Int) = x
  
  function Observers.update!(::typeof(g), results, result)
    empty!(results)
    push!(results, result)
  end
  
  function my_yet_another_iterative_function(niter::Int; observer!)
    for k in 1:niter
      x = k
      y = k * √2
      update!(observer!, x, y)
    end
  end
  
  obs = Observer(["g" => g, "f" => f])
  
  my_yet_another_iterative_function(100; observer! = obs)
  
  @test length( results(obs,"g")) == 1
  @test length( results(obs,"f")) == 100
end  
  
