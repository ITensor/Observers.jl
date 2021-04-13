module Observers

export Observer, func, results, update!

# TODO: allow optionally specifying the element type of the results
# if they are known ahead of time.
struct Observer <: AbstractDict{String, Pair{Function, Vector{Any}}}
  data::Dict{String, Pair{Function, Vector{Any}}}
  function Observer(kv)
    d = Dict{String, Pair{Function, Vector{Any}}}()
    for (k, v) in kv
      d[k] = v => Any[]
    end
    return new(d)
  end
end

Base.getindex(obs::Observer, n) = obs.data[n]
Base.length(obs::Observer) = length(obs.data)
Base.iterate(obs::Observer, args...) = iterate(obs.data, args...)

func(obs::Observer, n) = first(obs[n])
results(obs::Observer, n) = last(obs[n])

function update!(obs::Observer, args...; kwargs...)
  for (k, v) in obs
    func_k, results_k = obs[k]
    push!(results_k, func_k(args...; kwargs...))
  end
  return obs
end

end # module
