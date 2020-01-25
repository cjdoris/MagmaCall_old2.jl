Base.isassigned(o::MagmaObject) = magassigned(o)

Base.delete!(o::MagmaObject) = magdelete!(o)

function Base.print(io::IO, o::MagmaObject)
	if magassigned(o)
		magprint(io, o)
	else
		print(io, "NULL MagmaObject")
	end
end

function Base.show(io::IO, o::MagmaObject)
	if magassigned(o)
		magprintm(io, o)
	else
		print(io, "NULL")
	end
	get(io, :typeinfo, Union{}) == typeof(o) ||
		print(io, " :: ", typeof(o))
end

function Base.show(io::IO, ::MIME"text/plain", o::MagmaObject)
	if magassigned(o)
		magcallp(:__jl_display, o; _stdout=io)
	else
		print(io, "NULL")
	end
	get(io, :typeinfo, Union{}) == typeof(o) ||
		print(io, " :: ", typeof(o))	
end

Base.getproperty(o::MagmaObject, k::Symbol) =
	maggetattr(o, k)

Base.setproperty!(o::MagmaObject, k::Symbol, x) =
	magsetattr!(o, k, x)

Base.propertynames(o::MagmaObject) =
	magattrnames(o)

Base.hasproperty(o::MagmaObject, k::Symbol) =
	maghasattr(o, k)

Base.length(o::MagmaObject) =
	maglength(o)

Base.getindex(o::MagmaObject, a...) =
	maggetindex(o, a...)

Base.setindex!(o::MagmaObject, v, a...) =
	magsetindex!(o, v, a...)

Base.delete!(o::MagmaObject, a) =
	(magdelindex!(o, a); o)

Base.sort(o::MagmaObject) =
	magcallf(:Sort, o)

Base.sort!(o::MagmaObject) =
	(magcallp(:Sort, magref(o)); o)

Base.push!(o::MagmaObject, x) =
	(magcallp(:__jl_push, magref(o), x); o)

Base.pop!(o::MagmaObject) =
	(r=MagmaObject(false); magcallp(:__jl_pop, magref(r), magref(o)); r)

Base.pop!(o::MagmaObject, x) =
	(r=MagmaObject(false); magcallp(:__jl_pop, magref(r), magref(o), x); r)

Base.pop!(o::MagmaObject, x, y) =
	(r=MagmaObject(false); magcallp(:__jl_pop, magref(r), magref(o), x, y); r)

Base.append!(o::MagmaObject, x) =
	(magcallp(Symbol("cat:="), magref(o), x); o)

Base.maximum(o::MagmaObject) =
	magcallf(:Maximum, o)

Base.minimum(o::MagmaObject) =
	magcallf(:Minimum, o)

Base.argmax(o::MagmaObject) =
	magcallf2(:Maximum, o)[2]

Base.argmin(o::MagmaObject) =
	magcallf2(:Minimum, o)[2]

Base.findmin(o::MagmaObject) =
	magcallf2(:Minimum, o)

Base.findmax(o::MagmaObject) =
	magcallf2(:Maximum, o)

for (j,m) in [(:union,:join), (:intersect,:meet), (:setdiff,:diff), (:symdiff,:sdiff)]
	mm = QuoteNode(m)
	@eval Base.$j(a::MagmaObject, b::MagmaObject) = magcallf($mm, a, b)
	@eval Base.$j(a::MagmaObject, b) = magcallf($mm, a, b)
	@eval Base.$j(a, b::MagmaObject) = magcallf($mm, a, b)
	ji = Symbol(j,:!)
	mi = QuoteNode(Symbol(m,":="))
	@eval Base.$ji(a::MagmaObject, b) = (magcallp($mi, magref(a), b); a)
end

Base.issubset(a::MagmaObject, b::MagmaObject) = magcallb(:subset, a, b)
Base.issubset(a::MagmaObject, b) = magcallb(:subset, a, b)
Base.issubset(a, b::MagmaObject) = magcallb(:subset, a, b)

for (j,m) in [(:(==),:eq),(:(!=),:ne),(:<,:lt),(:≤,:le),(:>,:gt),(:≥,:ge)]
    mm = QuoteNode(m)
    @eval Base.$j(a::MagmaObject, b::MagmaObject) = magcallb($mm, a, b)
    @eval Base.$j(a::MagmaObject, b) = magcallb($mm, a, b)
    @eval Base.$j(a, b::MagmaObject) = magcallb($mm, a, b)
end

Base.hcat(a::MagmaObject, b::MagmaObject) = magcallf(:cat, a, b)
Base.hcat(a::MagmaObject, b) = magcallf(:cat, a, b)
Base.hcat(a, b::MagmaObject) = magcallf(:cat, a, b)

for (j,m) in [(:+,:+),(:-,:-)]
    mm = QuoteNode(m)
    @eval Base.$j(a::MagmaObject) = magcallf($mm, a)
end

for (j,m) in [(:+,:+),(:-,:-),(:*,:*),(:fld,:div),(:mod,:mod),(:^,:^)]
    mm = QuoteNode(m)
    @eval Base.$j(a::MagmaObject, b::MagmaObject) = magcallf($mm, a, b)
    @eval Base.$j(a::MagmaObject, b) = magcallf($mm, a, b)
    @eval Base.$j(a, b::MagmaObject) = magcallf($mm, a, b)
end

function Base.iterate(o::MagmaObject, state=nothing)
	if state===nothing
		oo = magcallf(:__jl_as_indexable, o)
		n = length(oo)
		i = 1
	else
		oo, n, i = state
	end
	i ≤ n ? (oo[i], (oo, n, i+1)) : nothing
end

Base.eltype(::Type{MagmaObject}) = MagmaObject

Base.convert(::Type{MagmaObject}, x::MagmaObject) = x
Base.convert(::Type{MagmaObject}, x::Sendable) = newobj(server_new(x))
Base.convert(::Type{MagmaObject}, x::AbstractVector) = magseq(x)
Base.convert(::Type{MagmaObject}, x::AbstractSet) = magset(x)

MagmaObject(x) = convert(MagmaObject, x)
