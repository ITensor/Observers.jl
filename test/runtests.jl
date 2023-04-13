using Compat
using DataFrames
using Observers
using Test

# Example Observer functions to use in tests.
# Need to define outside of `@testset` since the
# `@testset` mangles the names of functions that
# are defined in its scope.
iteration(; iteration) = iteration
err_from_π(; π_approx) = abs(π - π_approx) / π
nofunction() = missing
returns_test() = "test"

@testset "Observers" begin
  @testset "Examples" begin
    example_files = ["example1.jl", "README.jl"]
    for example_file in example_files
      include(joinpath(pkgdir(Observers), "examples", example_file))
    end
  end

  @testset "Deprecated" begin
    include("deprecated.jl")
  end

  @testset "Observer" begin
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

    obs = observer(["Error" => err_from_π, "Iteration" => iteration])

    @test ncol(obs) == 2
    @test obs.Error == []
    @test obs.Iteration == []

    niter = 10000
    observe_step = 1000
    π_approx = my_iterative_function(niter; (observer!)=obs, observe_step=observe_step)

    for res in eachcol(obs)
      @test length(res) == niter ÷ observe_step
    end

    obs = observer(["Error" => err_from_π, "Iteration" => iteration])
    insert_function!(obs, nofunction)
    error_sqr = (; π_approx) -> err_from_π(; π_approx)^2
    insert_function!(obs, "Error²", error_sqr)

    # Check deprecation
    @test_throws ErrorException results(obs)
    @test_throws ErrorException results(obs, "Error")

    @test names(obs) == ["Error", "Iteration", "nofunction", "Error²"]
    @test get_function(obs, "Error") == err_from_π
    @test get_function(obs, "nofunction") == nofunction
    @test get_function(obs, "Error²") == error_sqr
    for name in names(obs)
      @test obs[!, name] == Union{}[]
    end

    niter = 10000
    observe_step = 1000
    π_approx = my_iterative_function(niter; (observer!)=obs, observe_step=observe_step)

    @test nrow(obs) == niter ÷ observe_step
    @test all(ismissing, obs.nofunction)
    @test obs.Error .^ 2 == obs.Error²

    set_function!(obs, "Error" => Returns(12))
    insert_function!(obs, returns_test)

    @test get_function(obs, "Error") == Returns(12)
    @test get_function(obs, "returns_test") == returns_test
    @test all(ismissing, obs.returns_test)
    @test_throws ErrorException insert_function!(obs, "Error", Returns(11))
    @test_throws ArgumentError set_function!(obs, "New column", Returns(11))

    obs2 = copy(obs)
    π_approx = my_iterative_function(niter; (observer!)=obs2, observe_step=observe_step)

    @test nrow(obs2) == 2nrow(obs)
    first_half = 1:(niter ÷ observe_step)
    second_half = (niter ÷ observe_step + 1):(2 * niter ÷ observe_step)
    @test obs2.Error isa Vector{Float64}
    @test obs2.Error[first_half] == obs.Error
    @test all(==(12), obs2.Error[second_half])
    @test obs2.Iteration isa Vector{Int}
    @test obs2.Iteration[first_half] == obs.Iteration
    @test obs2.Iteration[second_half] == obs.Iteration
    @test obs2.Error² isa Vector{Float64}
    @test obs2.Error²[first_half] == obs.Error²
    @test obs2.Error²[second_half] == obs.Error²
    @test obs2.returns_test isa Vector{Union{Missing,String}}
    @test all(ismissing, obs2.returns_test[first_half])
    @test all(==("test"), obs2.returns_test[second_half])

    #
    # List syntax
    #

    obs = observer("Error" => err_from_π, "Iteration" => iteration)

    @test ncol(obs) == 2
    @test obs[!, "Error"] == []
    @test obs[!, "Iteration"] == []

    niter = 10000
    observe_step = 1000
    π_approx = my_iterative_function(niter; (observer!)=obs, observe_step=observe_step)

    for res in eachcol(obs)
      @test length(res) == niter ÷ observe_step
    end

    #
    # Function list syntax
    #

    obs = observer(err_from_π, iteration)

    @test ncol(obs) == 2
    @test_broken obs[!, err_from_π] == []
    @test obs[!, "err_from_π"] == []
    @test_broken obs[!, iteration] == []
    @test obs[!, "iteration"] == []

    niter = 10000
    observe_step = 1000
    π_approx = my_iterative_function(niter; (observer!)=obs, observe_step=observe_step)

    for res in eachcol(obs)
      @test length(res) == niter ÷ observe_step
    end

    f1(x::Int) = x^2
    f2(x::Int, y::Float64) = x + y
    f3(_, _, t::Tuple) = first(t)
    f4(x::Int; a::Float64) = x * a
    f5(x::Int; a::Float64, b::Float64) = x * a + b

    function my_other_iterative_function(; observer!)
      k = 2
      x = k
      y = k * √2
      t = (x + 2 * y, 0, 0)
      a = y^2
      b = 3.0
      return update!(observer!, x, y, t; a=a, b=b)
    end

    obs = observer(["f1" => f1, "f2" => f2, "f3" => f3, "f4" => f4, "f5" => f5])

    my_other_iterative_function(; (observer!)=obs)

    @test obs[!, "f1"][1] ≈ 4.0
    @test obs[!, "f2"][1] ≈ 2.0 + 2 * √2
    @test obs[!, "f3"][1] ≈ 2.0 + 4 * √2
    @test obs[!, "f4"][1] ≈ 16.0
    @test obs[!, "f5"][1] ≈ 19.0
  end

  @testset "Observer skip missing or nothing" begin
    obs = observer("x" => Returns(missing), "y" => Returns(missing))
    @test isempty(obs)
    update!(obs)
    @test isempty(obs)
    update!(obs; update!_kwargs=(; skip_all_missing=false))
    @test nrow(obs) == 1
    @test all(ismissing, obs[1, :])

    obs = observer("x" => Returns(nothing), "y" => Returns(nothing))
    @test isempty(obs)
    update!(obs)
    @test isempty(obs)
    update!(obs; update!_kwargs=(; skip_all_nothing=false))
    @test nrow(obs) == 1
    @test all(isnothing, obs[1, :])
  end

  @testset "Observer constructed from functions" begin
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

    obs = observer([err_from_π, iteration])

    @test ncol(obs) == 2
    @test obs[!, "err_from_π"] == []
    @test obs[!, "iteration"] == []

    niter = 10000
    observe_step = 1000
    π_approx = my_iterative_function(niter; (observer!)=obs, observe_step=observe_step)

    @test length(obs[!, "err_from_π"]) == niter ÷ observe_step
    @test length(obs[!, "iteration"]) == niter ÷ observe_step
    @test_broken length(results(obs, err_from_π)) == niter ÷ observe_step
    @test_broken length(results(obs, iteration)) == niter ÷ observe_step
    f1 = err_from_π
    f2 = iteration
    @test length(obs[!, string(f1)]) == niter ÷ observe_step
    @test length(obs[!, string(f2)]) == niter ÷ observe_step
    @test_broken length(obs[!, f1]) == niter ÷ observe_step
    @test_broken length(obs[!, f2]) == niter ÷ observe_step
    @test_throws ArgumentError obs[!, "f1"]
    @test_throws ArgumentError obs[!, "f2"]
  end

  @testset "save only last value" begin
    f(x::Int, y::Float64) = x + y
    g(x::Int) = x

    # function Observers.update!(::typeof(g), results, result)
    #   empty!(results)
    #   push!(results, result)
    # end

    function my_yet_another_iterative_function(niter::Int; observer!)
      for k in 1:niter
        x = k
        y = k * √2
        update!(observer!, x, y)
      end
    end

    obs = observer(["g" => g, "f" => f])

    my_yet_another_iterative_function(100; (observer!)=obs)

    @test length(obs[!, "g"]) == 100
    @test length(obs[!, "f"]) == 100
  end

  @testset "empty" begin
    f(x) = 2x
    function iterative(niter; observer!)
      for k in 1:niter
        update!(observer!, k)
      end
    end
    obs0 = observer(["f" => f])

    obs1 = copy(obs0)
    @test obs0 == obs1
    iterative(10; (observer!)=obs1)
    @test obs1 ≠ obs0
    empty!(obs1)
    @test obs1 == obs0

    iterative(10; (observer!)=obs1)
    obs1 = empty!(copy(obs0))
    @test obs1 == obs0
  end

  @testset "Test element types of Array" begin
    f(k, x::Int, y::Float64) = x + y
    g(k, x) = k < 20 ? 0 : exp(im * x)

    function iterative_function(niter::Int; observer!)
      for k in 1:niter
        x = k
        y = x * √2
        update!(observer!, k, x, y)
      end
    end

    obs = observer(["f" => f, "g" => g])
    iterative_function(100; (observer!)=obs)
    @test length(obs.f) == 100
    @test length(obs.g) == 100
    @test obs.f isa Vector{Float64}
    @test obs.g isa Vector{ComplexF64}

    obs = observer(["f" => f, "g" => g])
    iterative_function(10; (observer!)=obs)
    @test length(obs.f) == 10
    @test length(obs.g) == 10
    @test obs.f isa Vector{Float64}
    @test obs.g isa Vector{Int}
  end

  @testset "Function Returning nothing" begin
    function sumints(niter; observer!)
      total = 0
      for n in 1:niter
        total += n
        update!(observer!; total=total, iteration=n)
      end
      return total
    end

    running_total(; total, kwargs...) = total

    function every_other(; total, iteration, kwargs...)
      if iteration % 2 == 0
        return total
      end
      return missing
    end

    obs = observer(["RunningTotal" => running_total, "EveryOther" => every_other])

    niter = 100
    total = sumints(niter; (observer!)=obs)

    eo = obs.EveryOther
    rt = obs.RunningTotal

    # Test that `nothing` does not appear in eo:
    @test findfirst(isnothing, eo) == nothing

    # Test that eo contains every other value of rt:
    @test sum(!ismissing, eo) == div(length(rt), 2)
    @test eo[2:2:niter] == rt[2:2:niter]
    @test all(ismissing, eo[1:2:niter])
  end
end
