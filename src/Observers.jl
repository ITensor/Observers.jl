module Observers

import JLD: load, save

export Observer, func, results, update!, save, load

# TODO: allow optionally specifying the element type of the results
# if they are known ahead of time.
const FunctionAndResults = NamedTuple{(:f, :results), Tuple{Union{Nothing,Function}, Vector{Any}}}

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

Observer() = Observer(Dict{String, FunctionAndResults}())

Base.length(obs::Observer) = length(obs.data)
Base.iterate(obs::Observer, args...) = iterate(obs.data, args...)

Base.getindex(obs::Observer, n) = obs.data[n]

Base.setindex!(obs::Observer, observable::Union{Nothing,Function}, obsname::String) = 
  Base.setindex!(obs.data, (f = observable, results = Any[]), obsname)

Base.setindex!(obs::Observer, measurements::NamedTuple, obsname::String) = 
  Base.setindex!(obs.data, measurements, obsname)

Base.copy(observer::Observer) =  
  Observer([obsname => first(observer[obsname]) for obsname in keys(observer)])

results(observer::Observer, obsname::String) = 
  last(observer[obsname])

function update!(obs::Observer, args...; kwargs...)
  for (k, v) in obs
    obs_k = obs[k]
    if !isnothing(obs_k.f)
      push!(obs_k.results, obs_k.f(args...; kwargs...))
    end
  end
  return obs
end

function save(path::String, observer::Observer)
  if path[end-3:end] != ".jld"
    path = path * ".jld"
  end
  obsout = Dict([obsname => last(observer[obsname]) for obsname in keys(observer)])
  save(path, obsout)
end

end # module
