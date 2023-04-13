function results(observer::AbstractObserver, args...)
  return error(
    """The syntax `results(observer::Observer, "name")` and `results(observer::Observer)["name"]` for accessing results from an Observer are deprecated. You can access the results of an Observer directly with the DataFrames.jl syntax `observer.name` or `observer[!, "name"]`. As of Observers v0.1, Observer objects have the functionality and interface of DataFrame objects. See the [DataFrames documentation](https://dataframes.juliadata.org/stable/) for more details.""",
  )
end
