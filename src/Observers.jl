module Observers

export Observer, results, empty_results!, empty_results, update!

const FunctionAndResults = NamedTuple{(:f,:results),Tuple{Union{Nothing,Function},Any}}

struct Observer <: AbstractDict{String,FunctionAndResults}
  data::Dict{String,FunctionAndResults}
end

function Observer(key_function_pairs::Vector)
  d = Dict{String,FunctionAndResults}()
  for (k, v) in key_function_pairs
    d[k] = (f = v, results = Any[])
  end
  return Observer(d)
end

struct MissingMethod end

Observer() = Observer(Dict{String,FunctionAndResults}())

Base.length(obs::Observer) = length(obs.data)
Base.iterate(obs::Observer, args...) = iterate(obs.data, args...)

Base.getindex(obs::Observer, n) = obs.data[n]
Base.get(obs::Observer, n, x) = get(obs.data, n, x)

Base.setindex!(obs::Observer, observable::Union{Nothing,Function}, obsname::String) = 
  Base.setindex!(obs.data, (f = observable, results = Any[]), obsname)

Base.setindex!(obs::Observer, measurements::NamedTuple, obsname::String) = 
  Base.setindex!(obs.data, measurements, obsname)

Base.setindex!(obs::Observer, measurements::Tuple{Union{Nothing,Function},Vector{Any}}, obsname::String) = 
  Base.setindex!(obs.data, (f = first(measurements), results = last(measurements)), obsname)

Base.copy(observer::Observer) = Observer(copy(observer.data))

Base.empty!(observer::Observer) = empty!(observer.data)

function empty_results!(observer::Observer, k)
  empty!(results(observer, k))
  return observer
end

function empty_results!(observer::Observer)
  for k in keys(observer)
    empty_results!(observer, k)
  end
  return observer
end

empty_results(observer::Observer, args...) = empty_results!(copy(observer), args...)

results(observer::Observer, obsname::String) = 
  observer[obsname].results

function set_results!(observer::Observer, results, obsname::String)
  observer[obsname] = (f=observer[obsname].f, results=results)
  return observer
end

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
      update!(obs, obs_k.f, k, result)
    end
  end
  return obs
end

function update!(obs::Observer, f::Function, k, result)
  if result isa eltype(obs[k].results) && !isempty(obs[k].results)
    update!(f, obs[k].results, result)
  elseif isempty(obs[k].results)
    # This sets the type of the results to the type
    # of the initial results.
    set_results!(obs, [result], k)
  else
    # If the type of the result doesn't fit into the current
    # results storage, convert the results.
    T = promote_type(typeof(result), eltype(obs[k].results))
    obs_k_results = convert(Vector{T}, obs[k].results)
    update!(f, obs_k_results, result)
    set_results!(obs, obs_k_results, k)
  end
end

# Allows external users to customize updating the results for
# a given function, for example by emptying them.
update!(f::Function, results, result) = push!(results, result)

end # module
