@deprecate Observer observer

function results(::AbstractDataFrame, args...)
  return error(
    """The syntax `results(observer, "name")` and `results(observer)["name"]` for accessing results from an observer are deprecated. You can access the results of an observer directly with the DataFrames.jl syntax `observer.name` or `observer[!, "name"]`. As of Observers v0.2, observers are just `DataFrame`s from DataFrames.jl. See the [DataFrames documentation](https://dataframes.juliadata.org/stable/) for more details on supported functionality.""",
  )
end
