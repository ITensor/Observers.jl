using Compat
using DataFrames
using JLD2
using Observers
using SplitApplyCombine
using Statistics
using TableMetadataTools
using TableOperations
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

    obs = Observer(["Error" => err_from_π, "Iteration" => iteration])

    @test ncol(obs) == 2
    @test obs.Error == []
    @test obs.Iteration == []

    niter = 10000
    observe_step = 1000
    π_approx = my_iterative_function(niter; (observer!)=obs, observe_step=observe_step)

    for res in eachcol(obs)
      @test length(res) == niter ÷ observe_step
    end

    jldsave("outputdata.jld2"; obs)
    obs_load = load("outputdata.jld2", "obs")

    for j in 1:nrow(obs_load)
      @test obs_load[j, :] == obs[j, :]
    end

    obs = Observer(["Error" => err_from_π, "Iteration" => iteration])
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

    obs = Observer("Error" => err_from_π, "Iteration" => iteration)

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

    obs = Observer(err_from_π, iteration)

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

    obs = Observer(["f1" => f1, "f2" => f2, "f3" => f3, "f4" => f4, "f5" => f5])

    my_other_iterative_function(; (observer!)=obs)

    @test obs[!, "f1"][1] ≈ 4.0
    @test obs[!, "f2"][1] ≈ 2.0 + 2 * √2
    @test obs[!, "f3"][1] ≈ 2.0 + 4 * √2
    @test obs[!, "f4"][1] ≈ 16.0
    @test obs[!, "f5"][1] ≈ 19.0
  end

  @testset "Observer skip missing or nothing" begin
    obs = Observer("x" => Returns(missing), "y" => Returns(missing))
    @test isempty(obs)
    update!(obs)
    @test isempty(obs)
    update!(obs; update!_kwargs=(; skip_all_missing=false))
    @test nrow(obs) == 1
    @test all(ismissing, obs[1, :])

    obs = Observer("x" => Returns(nothing), "y" => Returns(nothing))
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

    obs = Observer([err_from_π, iteration])

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

    obs = Observer(["g" => g, "f" => f])

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
    obs0 = Observer(["f" => f])

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

    obs = Observer(["f" => f, "g" => g])
    iterative_function(100; (observer!)=obs)
    @test length(obs.f) == 100
    @test length(obs.g) == 100
    @test obs.f isa Vector{Float64}
    @test obs.g isa Vector{ComplexF64}

    obs = Observer(["f" => f, "g" => g])
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

    obs = Observer(["RunningTotal" => running_total, "EveryOther" => every_other])

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

  @testset "Conversion to DataFrames" begin
    f(k, x::Int, y::Float64) = x + y
    g(k, x) = k < 20 ? 0 : exp(im * x)
    function iterative_function(niter::Int; observer!)
      for k in 1:niter
        x = k
        y = x * √2
        update!(observer!, k, x, y)
      end
    end
    obs = Observer(["f" => f, "g" => g])
    iterative_function(100; (observer!)=obs)
    df = DataFrame(obs)
    @test df.f == obs.f
    @test df.g == obs.g
    @test length(df.f) == 100
    @test length(df.g) == 100
    @test df.f isa Vector{Float64}
    @test df.g isa Vector{ComplexF64}
  end

  @testset "DataFrames functionality" begin
    o = Observer(DataFrame((a=[1, 2], b=[3, 4])))

    # https://tables.juliadata.org/stable/#Implementing-the-Interface-(i.e.-becoming-a-Tables.jl-source)
    # https://github.com/JuliaData/TableOperations.jl
    @test Tables.rows(o) isa DataFrames.DataFrameRows
    @test Tables.columns(o) isa DataFrames.DataFrameColumns
    @test Tables.columnnames(o) == [:a, :b]
    row = Tables.rows(o)[1]
    @test [Tables.getcolumn(row, col) for col in Tables.columnnames(row)] == [1, 3]
    row = Tables.rows(o)[2]
    @test [Tables.getcolumn(row, col) for col in Tables.columnnames(row)] == [2, 4]
    col = Tables.columnnames(Tables.columns(o))[1]
    @test Tables.getcolumn(Tables.columns(o), col) == [1, 2]
    col = Tables.columnnames(Tables.columns(o))[2]
    @test Tables.getcolumn(Tables.columns(o), col) == [3, 4]
    @test Tables.subset(o, 2:2) isa DataFrame
    @test Tables.subset(o, 2:2) == DataFrame((; a=[2], b=[4]))
    @test Tables.istable(typeof(o))
    @test Tables.rowaccess(typeof(o))
    @test Tables.rows(o) isa DataFrames.DataFrameRows
    @test Tables.columnaccess(typeof(o))
    @test Tables.columns(o) isa DataFrames.DataFrameColumns
    @test Tables.schema(o) isa Tables.Schema
    @test Tables.materializer(typeof(o)) <: DataFrame

    # TableOperations.jl
    @test Tables.columntable(TableOperations.select(:a)(o)) == (; a=[1, 2])
    @test DataFrame(TableOperations.select(:a)(o)) == DataFrame((; a=[1, 2]))
    @test DataFrame(TableOperations.transform(; a=x -> Symbol(x))(o)) ==
      DataFrame((; a=[Symbol(1), Symbol(2)], b=[3, 4]))
    @test DataFrame(TableOperations.filter(x -> Tables.getcolumn(x, :b) > 3)(o)) ==
      DataFrame((; a=[2], b=[4]))
    @test DataFrame(
      TableOperations.map(
        x -> (a=Tables.getcolumn(x, :b) * 2, b=Tables.getcolumn(x, :a) * 2)
      )(
        o
      ),
    ) == DataFrame((; a=[6, 8], b=[2, 4]))

    @test copy(o) == o
    @test names(o) == ["a", "b"]
    @test propertynames(o) == [:a, :b]
    @test eltype.(eachcol(o)) == [Int, Int]
    @test nrow(o) == 2
    @test ncol(o) == 2
    @test size(o) == (2, 2)
    @test size(o, 1) == 2
    @test size(o, 2) == 2
    @test o.a == [1, 2]
    @test o.b == [3, 4]
    oc = copy(o)
    oc.a = ["x", "y"]
    @test oc.a == ["x", "y"]
    @test o.b == [3, 4]
    oc = copy(o)
    append!(oc, DataFrame((a=[10, 20], b=[30, 40])))
    @test oc.a == [1, 2, 10, 20]
    @test oc.b == [3, 4, 30, 40]
    oc = copy(o)
    prepend!(oc, DataFrame((a=[15, 25], b=[35, 45])))
    @test oc.a == [15, 25, 1, 2]
    @test oc.b == [35, 45, 3, 4]
    @test empty(o) == Observer(DataFrame((a=Int[], b=Int[])))
    @test isempty(empty(o))
    @test empty!(copy(o)) == Observer(DataFrame((a=Int[], b=Int[])))
    @test describe(o) isa DataFrame
    @test describe(o; cols=1:1) isa DataFrame
    io = IOBuffer()
    show(io, o; allcols=true)
    @test String(take!(io)) isa String

    # Statistics.jl
    @test mean(o.a) == 1.5
    oc = mapcols(id -> id .^ 2, o)
    @test oc.a == [1, 4]
    @test oc.b == [9, 16]
    @test first(o, 1) isa DataFrame
    @test nrow(first(o, 1)) == 1
    @test first(o) isa DataFrameRow
    @test last(o, 1) isa DataFrame
    @test nrow(last(o, 1)) == 1
    @test last(o) isa DataFrameRow
    oc = sort(o; rev=true)
    @test oc isa DataFrame
    @test oc.a == [2, 1]
    @test oc.b == [4, 3]
    oc = subset(o, :a => x -> x .> 1)
    @test oc isa DataFrame
    @test oc.a == [2]
    @test oc.b == [4]
    @test o[1, [:a]] isa DataFrameRow
    @test size(o[1, [:a]]) == (1,)
    @test o[1, [:a]].a == 1
    @test o[1:1, [:a]] isa DataFrame
    @test size(o[1:1, [:a]]) == (1, 1)
    @test o[1:1, [:a]].a == [1]
    oc = copy(o)
    oc[:, [:a]] = [4 5]'
    @test oc.a == [4, 5]
    @test oc.b == [3, 4]
    oc[!, [:a, :b]] = [8 9; 10 11]
    @test oc.a == [8, 10]
    @test oc.b == [9, 11]
    oc[:, :a] = [12, 13]
    @test oc.a == [12, 13]
    oc[1, :a] = 45
    @test oc.a == [45, 13]

    # https://dataframes.juliadata.org/stable/man/split_apply_combine/
    # SplitApplyCombine.jl
    oc = copy(o)
    pushfirst!(oc, Dict(:a => 10, :b => 3))
    oc_grouped = groupby(oc, :b)
    @test oc_grouped isa GroupedDataFrame
    @test length(oc_grouped) == 2
    @test keys(oc_grouped) == [(; b=3), (; b=4)]
    @test oc_grouped[(; b=3)].a == [10, 1]
    @test oc_grouped[(; b=3)].b == [3, 3]
    @test oc_grouped[(; b=4)].a == [2]
    @test oc_grouped[(; b=4)].b == [4]

    # https://dataframes.juliadata.org/stable/lib/metadata/
    oc = copy(o)
    colmetadata!(oc, :a, "function", sin; style=:note)
    colmetadata!(oc, :b, "function", cos; style=:note)
    @test colmetadata(oc, :a, "function") == sin
    @test colmetadata(oc, :b, "function") == cos
    oc = Observer(sort(oc; rev=true))
    @test oc isa DataFrame
    @test colmetadata(oc, :a, "function") == sin
    @test colmetadata(oc, :b, "function") == cos

    df = DataFrame(o)
    @test colmetadata(df) == colmetadata(o)
    @test df.a == o.a
    @test df.b == o.b
    @test df == o

    # TableMetadataTools.jl
    # https://github.com/JuliaData/TableMetadataTools.jl
    # https://github.com/JuliaData/TableMetadataTools.jl/blob/main/docs/demo.ipynb
    @test label(o, :a) == "a"
    @test label(o, :b) == "b"
    @test labels(o) == ["a", "b"]
    @test findlabels(contains("a"), o) == [:a => "a"]
    @test note(o) == ""
    @test note(o, :a) == ""
    @test note(o, :b) == ""
    oc = copy(o)
    oc = caption!(oc, "o_caption")
    @test caption(oc) == "o_caption"
    oc = copy(o)
    oc = note!(oc, "o_note")
    @test note(oc) == "o_note"
    oc = copy(o)
    metadata!(oc, "x1", "y1")
    metadata!(oc, "x2", "y2")
    @test metadata(oc, "x1") == "y1"
    @test metadata(oc, "x2") == "y2"
    label!(oc, :a, "al1")
    note!(oc, :a, "a1")
    note!(oc, :a, "a2"; append=true)
    @test label(oc, :a) == "al1"
    @test note(oc, :a) == "a1\na2"
    @test meta2toml(oc) isa String
    @test !isempty(metadata(oc))
    @test !isempty(colmetadata(oc))
    emptymetadata!(oc)
    @test isempty(metadata(oc))
    @test !isempty(colmetadata(oc))
    emptycolmetadata!(oc)
    @test isempty(metadata(oc))
    @test isempty(colmetadata(oc))
    metadata!(oc, "a", "a1")
    metadata!(oc, "b", "b1")
    @test metadata(oc) == Dict("a" => "a1", "b" => "b1")
    deletemetadata!(oc, "a")
    @test metadata(oc) == Dict("b" => "b1")
    colmetadata!(oc, :a, "aa", "aa1"; style=:note)
    colmetadata!(oc, :a, "ab", "ab1"; style=:note)
    colmetadata!(oc, :b, "ba", "ba1"; style=:note)
    colmetadata!(oc, :b, "bb", "bb1"; style=:note)
    @test colmetadata(oc, :a) == Dict("aa" => "aa1", "ab" => "ab1")
    @test colmetadata(oc, :b) == Dict("ba" => "ba1", "bb" => "bb1")
    deletecolmetadata!(oc, :a, "aa")
    @test colmetadata(oc, :a) == Dict("ab" => "ab1")
    oc = oc[:, [:b]]
    @test ncol(oc) == 1
    @test colmetadata(oc, :b) == Dict("ba" => "ba1", "bb" => "bb1")

    # TODO: Extract more tests from these sources:
    # https://dataframes.juliadata.org/stable/man/basics/#Getting-and-Setting-Data-in-a-Data-Frame
    # https://dataframes.juliadata.org/stable/man/getting_started/#The-DataFrame-Type
    # https://dataframes.juliadata.org/stable/man/working_with_dataframes/#Taking-a-Subset
    # https://dataframes.juliadata.org/stable/man/working_with_dataframes/#Selecting-and-transforming-columns
    # https://dataframes.juliadata.org/stable/man/working_with_dataframes/#Handling-of-Columns-Stored-in-a-DataFrame
    # https://dataframes.juliadata.org/stable/man/working_with_dataframes/#Replacing-Data
    # https://dataframes.juliadata.org/stable/man/importing_and_exporting/#CSV-Files
    # https://dataframes.juliadata.org/stable/man/joins/
    # https://dataframes.juliadata.org/stable/man/split_apply_combine/#Examples-of-the-split-apply-combine-operations
    # https://dataframes.juliadata.org/stable/man/reshaping_and_pivoting/#Reshaping-and-Pivoting-Data
    # https://dataframes.juliadata.org/stable/man/sorting/#Sorting
    # https://dataframes.juliadata.org/stable/man/missing/#Missing-Data
  end
end
