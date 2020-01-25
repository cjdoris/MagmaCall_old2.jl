magassigned(o::MagmaObject) = _id(o) != 0
export magassigned

id(o::MagmaObject) = magassigned(o) ? _id(o) : throw(MagmaNotAssignedError())

function magdelete!(o::MagmaObject)
	checkb(server_delete(id(o)))
	setfield!(o, :id, 0)
	o
end
export magdelete!

magprint(io::IO, o::MagmaObject) =
	checkb(server_print(io, id(o)))
export magprint

magprintm(io::IO, o::MagmaObject) =
	checkb(server_printm(io, id(o)))
export magprintm

maguniverse(x) =
	magcallf(:Universe, x)
export maguniverse

magchangeuniverse!(x, u) =
	(magcallp(:ChangeUniverse, magref(x), u); x)
export magchangeuniverse!

magseq(; universe=nothing) =
	newobj(universe===nothing ? server_newseq() : server_newseq(universe))
function magseq(xs; opts...)
	r = magseq(;opts...)
	for x in xs
	    magcallp(:Append, magref(r), x)
	end
	r
end
function magseq(xs::Union{MagmaObject, SendableCollection}; universe=nothing)
	r = magcallf(:__jl_as_sequence, xs)
	if universe !== nothing
		magchangeuniverse!(r, universe)
	end
	r
end
export magseq

magset(; universe=nothing) =
	newobj(universe===nothing ? server_newset() : server_newset(universe))
function magset(xs; opts...)
	r = magset(;opts...)
	for x in xs
	    magcallp(:Include, magref(r), x)
	end
	r
end
function magset(xs::Union{MagmaObject, SendableCollection}; universe=nothing)
	r = magcallf(:__jl_as_set, xs)
	if universe !== nothing
		magchangeuniverse!(r, universe)
	end
	r
end
export magset

maglist() = newobj(server_newlist())
function maglist(xs)
	r = maglist()
	for x in xs
	    magcallp(:Include, magref(r), x)
	end
	r
end
maglist(xs::Union{MagmaObject, SendableCollection}) =
	magcallf(:__jl_as_list, xs)
export maglist

magrange(b) = magrange(1, b)
magrange(a, b) = newobj(server_newseqrange(a, b))
magrange(a, b, c) = newobj(server_newseqrange(a, b, c))
export magrange

magsetrange(b) = magsetrange(1, b)
magsetrange(a, b) = newobj(server_newsetrange(a, b))
magsetrange(a, b, c) = newobj(server_newsetrange(a, b, c))
export magsetrange

maggetattr(o::MagmaObject, k::Symbol) =
	newobj(server_getattr(id(o), k))
export maggetattr

magsetattr!(o::MagmaObject, k::Symbol, x) =
	checkb(server_setattr(o, k, x))
export magsetattr!

magattrnames(o::MagmaObject) =
	check(server_attrnames(id(o)))
export magattrnames

maghasattr(o::MagmaObject, k::Symbol) =
	check(server_hasattr(id(o), k))
export maghasattr

magattrisassigned(o::MagmaObject, k::Symbol) =
	check(server_attrisassigned(id(o), k))
export magattrisassigned

@generated function magcall(::Val{R}, f, args...; _stdout=stdout, opts...) where {R}
	if R isa Int && R ≥ 0
		N = R
		cmd = "call"
	elseif R == :bool
		N = 1
		cmd = "callb"
	elseif R == :int
		N = 1
		cmd = "calli"
	else
		error("R must be a non-negative integer, :bool or :int")
	end
	optnames = opts.parameters[4].parameters[1]
	refs = [<:(a,MagmaRef) for a in args]
	ap = string(join([r ? '~' : '.' for r in refs]), ':', join(optnames, ':'))
	fx = gensym()
	axs = [gensym() for a in args]
	oxs = [gensym() for n in optnames]
	rxs = [gensym() for i in 1:N]
	retcode =
		R == :bool ? :(server_readbool()) :
		R == :int  ? :(server_readint()) :
		quote
			$([:($n = newobj(server_readint())) for n in rxs]...)
			$(N==0 ? :(return) : N==1 ? :(return $(rxs[1])) : :(return ($(rxs...),)))
		end
	quote
		$fx = $(f==Symbol ? :(MagmaIntrinsic(f)) : :(assendable(f)))
		$([:($n = asarg(args[$i])) for (i,n) in enumerate(axs)]...)
		$([:($n = assendable(opts[$(QuoteNode(m))])) for (i,(n,m)) in enumerate(zip(oxs,optnames))]...)
		Base.GC.@preserve $([fx; axs; oxs]...) begin
			server_send($cmd, $ap, $N)
			server_sendval($fx)
			$([r ? :(server_send(id($n.o))) : :(server_sendval($n)) for (n,r) in zip(axs,refs)]...)
			$([:(server_sendval($n)) for n in oxs]...)
		end
		server_printtotoken(_stdout)
		server_readbool() || magruntimeerror()
		$retcode
	end
end
export magcall

magcall(N::Int, f, args...; opts...) =
	magcall(Val(N), f, args...; opts...)

magcallp(f, args...; opts...) =
	magcall(Val(0), f, args...; opts...)
export magcallp

magcallf(f, args...; opts...) =
	magcall(Val(1), f, args...; opts...)
export magcallf

magcallb(f, args...; opts...) =
	magcall(Val(:bool), f, args...; opts...)
export magcallb

magcalli(f, args...; opts...) =
	magcall(Val(:int), f, args...; opts...)
export magcalli

for N in 1:20
	fn = Symbol(:magcallf, N)
    @eval $fn(f, args...; opts...) =
    	magcall($(Val(N)), f, args...; opts...)
    @eval export $fn
end

magtype(x::MagmaType) = MagmaObject(x)
magtype(x::MagmaSymbol) = magtype(x.name)
magtype(x::Symbol) = magtype(MagmaType(x))
export magtype

magintr(x::MagmaIntrinsic) = MagmaObject(x)
magintr(x::MagmaSymbol) = magintr(x.name)
magintr(x::Symbol) = magintr(MagmaIntrinsic(x))
export magintr

magtypeof(x) = magcallf(:Type, x)
export magtypeof

magetypeof(x) = magcallf(:ExtendedType, x)
export magetypeof

magissubtype(s, t) =
	magcallb(:ISA, s isa Symbol ? MagmaType(s) : s, t isa Symbol ? MagmaType(t) : t)
export magissubtype

magisa(x, t) = magissubtype(magetypeof(x), t)
export magisa

maglength(x) = magcalli(Symbol("#"), x)
export maglength

maggetindex(x::MagmaObject, a...) =
	newobj(server_getindex(id(x), map(assendable, a)...))
export maggetindex

magsetindex!(x::MagmaObject, v, a...) =
	checkb(server_setindex(id(x), assendable(v), map(assendable, a)...))
export magsetindex!

magdelindex!(x::MagmaObject, a) =
	magcallp(:__jl_delindex, magref(x), a)
export magdelindex!

maggen(x::MagmaObject, i) =
	magcallf(:., x, i)
export magname

@generated function maggens!(x::MagmaObject, gens::Symbol...)
	n = length(gens)
	quote
		gs = push!(magseq(), $([:(String(gens[$i])) for i in 1:n]...))
		magcallp(:AssignNames, magref(x), gs)
		return (x, $([:(maggen(x, $i)) for i in 1:n]...))
	end
end
export maggens!

macro maggens(ex::Expr)
	ex.head == :(=) || @goto ERR
	lhs, rhs = ex.args
	lhs.head == :ref || @goto ERR
	vars = lhs.args
	all(v->v isa Symbol, vars) || @goto ERR
	return quote
		($(map(esc, vars)...),) = maggens!($(esc(rhs)), $(map(QuoteNode, vars[2:end])...))
		$(esc(vars[1]))
	end
	@label ERR
	error("argument must be of the form `R[x,y,z] = ...`")
end
export @maggens

magcallg(f, gens::Tuple{Vararg{Symbol}}, args...; opts...) =
	maggens!(magcallf(f, args...; opts...), gens...)
magcallg(f, gen::Symbol, args...; opts...) =
	magcallg(f, (gen,), args...; opts...)
export magcallg

magcoerce(S::MagmaObject, x) =
	magcallf(:!, S, x)
export magcoerce

function maghelp(args...; io=stdout)
	q = strip(string(args...))
	isempty(q) && (q = "/")
	server_stop()
	println(proc[], "?", q)
	println(proc[], "print \"$(token)\";")
	server_printtotoken(io)
	server_start()
end
export maghelp
