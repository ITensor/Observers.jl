module Observers

export Observer, func, results, update!

# TODO: allow optionally specifying the element type of the results
# if they are known ahead of time.
const FunctionAndResults = NamedTuple{(:f, :results), Tuple{Function, Vector{Any}}}

struct Observer <: AbstractDict{String, FunctionAndResults}
  data::Dict{String, FunctionAndResults}
  function Observer(kv)
    d = Dict{String, FunctionAndResults}()
    for (k, v) in kv
      d[k] = (f = v, results = Any[])
    end
    return new(d)
  end
end

Base.getindex(obs::Observer, n) = obs.data[n]
Base.length(obs::Observer) = length(obs.data)
Base.iterate(obs::Observer, args...) = iterate(obs.data, args...)

function update!(obs::Observer, args...; kwargs...)
  for (k, v) in obs
    obs_k = obs[k]
    push!(obs_k.results, obs_k.f(args...; kwargs...))
  end
  return obs
end

end # module
