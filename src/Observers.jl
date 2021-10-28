module Observers

export Observer, functions_and_results, results, update!

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

struct MissingMethod end

Observer() = Observer(Dict{String, FunctionAndResults}())

Base.length(obs::Observer) = length(obs.data)
Base.iterate(obs::Observer, args...) = iterate(obs.data, args...)

Base.getindex(obs::Observer, n) = obs.data[n]
Base.get(obs::Observer, n, x) = get(obs.data, n, x)

Base.setindex!(obs::Observer, observable::Union{Nothing,Function}, obsname::String) = 
  Base.setindex!(obs.data, (f = observable, results = Any[]), obsname)

Base.setindex!(obs::Observer, measurements::NamedTuple, obsname::String) = 
  Base.setindex!(obs.data, measurements, obsname)

Base.setindex!(obs::Observer, measurements::Tuple{Union{Nothing,Function}, Vector{Any}}, obsname::String) = 
  Base.setindex!(obs.data, (f = first(measurements), results = last(measurements)), obsname)

Base.copy(observer::Observer) =  
  Observer([obsname => first(observer[obsname]) for obsname in keys(observer)])

results(observer::Observer, obsname::String) = 
  last(observer[obsname])

functions_and_results(obs::Observer) = 
  obs.data

results(observer::Observer) =
  Dict([obsname => last(observer[obsname]) for obsname in keys(observer)])

"""
    update!(obs::Observer, args...; kwargs...)

Update the observer by executing the functions in it.
"""
function update!(obs::Observer, args...; kwargs...)
  # loop over the functions
  for (k, v) in obs
    obs_k = obs[k]
    # if a function is defined
    if !isnothing(obs_k.f)
      # collect the types of each positional argument being passed into the observer
      args_types = typeof.(args)
      # initialize the result to catch a method not being found
      result = MissingMethod() 
      # loop over the sequences of possible positional arguments
      for i in 0:length(args_types)
        tlist = args_types[1:i]
        # if a function with argument matching tlist exists:
        if hasmethod(obs_k.f, tlist)
          # check the kwargs of such function
          kwargs_list = Base.kwarg_decl(which(obs_k.f, tlist))
          # remove the kwargs... from the kwargs
          filter!(x -> !(length(string(x)) ≥ 4 && string(x)[end-2:end] == "..."), kwargs_list)
          # execute the function
          result = obs_k.f(args[1:i]...; (kwargs_list .=> [kwargs[κ] for κ in kwargs_list])...)
          break
        end
      end
      result isa MissingMethod && error("No method found")
      update!(obs_k.f, obs_k.results, result)
    end
  end
  return obs
end

update!(f::Function, results, result) = 
  push!(results, result)

end # module
