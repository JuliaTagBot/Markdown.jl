typealias InnerConfig Dict{Char, Vector{Function}}

type Config
  breaking::Vector{Function}
  regular::Vector{Function}
  inner::InnerConfig
end

Config() = Config(Function[], Function[], InnerConfig())

const META = Dict{Function, Dict{Symbol, Any}}()

getset(coll, key, default) = coll[key] = get(coll, key, default)

meta(f) = getset(META, f, Dict{Symbol, Any}())

breaking!(f) = meta(f)[:breaking] = true
breaking(f) = get(meta(f), :breaking, false)

triggers!(f, ts) = meta(f)[:triggers] = Set{Char}(ts)
triggers(f) = get(meta(f), :triggers, Set{Char}())

# Macros

isexpr(x::Expr, ts...) = x.head in ts
isexpr{T}(x::T, ts...) = T in ts

macro breaking (def)
  quote
    f = $(esc(def))
    breaking!(f)
    f
  end
end

macro trigger (ex)
  isexpr(ex, :->) || error("invalid @triggers form, use ->")
  ts, def = ex.args
  quote
    f = $(esc(def))
    triggers!(f, $ts)
    f
  end
end

function config(parsers::Function...)
  c = Config()
  for parser in parsers
    ts = triggers(parser)
    if breaking(parser)
      push!(c.breaking, parser)
    elseif !isempty(ts)
      for t in ts
        push!(getset(c.inner, t, Function[]), parser)
      end
    else
      push!(c.regular, parser)
    end
  end
  return c
end
