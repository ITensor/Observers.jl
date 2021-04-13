module Observer

export Observers, func, results, update!

# TODO: Rename Observer
# TODO: allow optionally specifying the element type of the results
# if they are known ahead of time.
struct Observers <: AbstractDict{String, Pair{Function, Vector{Any}}}
  data::Dict{String, Pair{Function, Vector{Any}}}
  function Observers(kv)
    d = Dict{String, Pair{Function, Vector{Any}}}()
    for (k, v) in kv
      d[k] = v => Any[]
    end
    return new(d)
  end
end

Base.getindex(obs::Observers, n) = obs.data[n]
Base.length(obs::Observers) = length(obs.data)
Base.iterate(obs::Observers, args...) = iterate(obs.data, args...)

func(obs::Observers, n) = first(obs[n])
results(obs::Observers, n) = last(obs[n])

function update!(obs::Observers, args...; kwargs...)
  for (k, v) in obs
    func_k, results_k = obs[k]
    push!(results_k, func_k(args...; kwargs...))
  end
  return obs
end

end # module
