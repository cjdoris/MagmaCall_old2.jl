const magmaexe = "magma"
const serverpath = joinpath(dirname(dirname(@__FILE__)), "server.mag")
const proc = Ref{Base.Process}()
const procon = Ref(false)
const token = String(rand(UInt8('A'):UInt8('Z'), 12))

function __init__()
	proc[] = open(`$magmaexe -b`, "r+")
	procon[] = true
	atexit() do
		procon[] = false
		kill(proc[])
	end
	server_attach()
	server_start()
end

function server_attach()
	println(proc[], "Attach(\"$serverpath\");")
end

function server_settoken(tok=token)
	println(proc[], "__jl_server_settoken($(repr(tok)));")
end

function server_start(; token=token)
	server_settoken(token)
	println(proc[], "__jl_server_start();")
	server_check()
end

function server_stop()
	server_send("stop")
end

function server_send(xs...)
	for x in xs
		println(proc[], x)
	end
end

function server_check()
	server_send("ping")
	server_readtoken()
end

function server_readline()
	readline(proc[])
end

function server_readtoken()
	r = server_readline()
	r == token ||
		throw(MagmaServerInvalidResponseError("token", r))
	nothing
end

function server_readbool()
	r = server_readline()
	r == "true" ? true : r == "false" ? false :
		throw(MagmaServerInvalidResponseError("bool", r))
end

function server_readbool_check()
	server_readtoken()
	server_readbool() || (return nothing)
	server_readbool()
end

function server_readint()
	r = server_readline()
	i = tryparse(Int, r)
	i !== nothing ? i :
		throw(MagmaServerInvalidResponseError("int", r))
end

function server_readint_check()
	server_readtoken()
	server_readbool() || (return nothing)
	server_readint()
end

function server_isrunning()
	server_send("__jl_server_running();")
	server_readbool()
end

# nothing on fail
function server_isassigned(i::Int)
	server_send("assigned", i)
	server_readbool_check()
end

# true on success
function server_assign(i::Int, x::Sendable)
	server_send(":=", i)
	server_sendval(x)
	server_readtoken()
	server_readbool()
end

# nothing on fail
function server_new(x::Sendable)
	server_send("new:=")
	server_sendval(x)
	server_readint_check()
end

function server_newseq()
	server_send("new:=", "[]")
	server_readint_check()
end

function server_newseq(u::Sendable)
	server_send("new:=", "[|]")
	server_sendval(u)
	server_readint_check()
end

function server_newset()
	server_send("new:=", "{}")
	server_readint_check()
end

function server_newset(u::Sendable)
	server_send("new:=", "{|}")
	server_readint_check()
end

function server_newlist()
	server_send("new:=", "[**]")
	server_readint_check()
end

function server_newseqrange(a::Sendable, b::Sendable)
	server_send("new:=", "[..]")
	server_sendval(a, b)
	server_readint_check()
end

function server_newseqrange(a::Sendable, b::Sendable, c::Sendable)
	server_send("new:=", "[..by]")
	server_sendval(a, b, c)
	server_readint_check()
end

function server_newsetrange(a::Sendable, b::Sendable)
	server_send("new:=", "{..}")
	server_sendval(a, b)
	server_readint_check()
end

function server_newsetrange(a::Sendable, b::Sendable, c::Sendable)
	server_send("new:=", "{..by}")
	server_sendval(a, b, c)
	server_readint_check()
end

# true on success
function server_delete(i::Int)
	server_send("delete", i)
	server_readtoken()
	server_readbool()
end

function server_sendval(x::MagmaObject)
	server_send("var", id(x))
end

function server_sendval(x::Integer)
	server_send("int", asstdint(x))
end

function server_sendval(x::Bool)
	server_send(x ? "true" : "false")
end

function server_sendval(x::AbstractString)
	all(isascii, x) || error("magma only supports ASCII strings")
	server_send("str", length(x), x)
end

function server_sendval(x::OrdinalRange{<:Integer,<:Integer})
	server_send("[..by]")
	server_sendval(first(x), last(x), step(x))
end

function server_sendval(x::AbstractUnitRange{<:Integer})
	server_send("[..]")
	server_sendval(first(x), last(x))
end

function server_sendval(x::MagmaIntrinsic)
	server_send("intr", x.name)
end

function server_sendval(x::MagmaType)
	server_send("type", x.name)
end

function server_sendval(x::MagmaSymbol)
	server_send("sym", x.name)
end

function server_sendval(x::Union{Float16,Float32,Float64})
	server_send("real", x)
end

function server_sendval(x::BigFloat)
	server_send("real", "xp$(floor(Int, precision(x)/log2(10)))")
end

function server_sendval(x::AbstractFloat)
	server_sendval(convert(BigFloat, x))
end

function server_sendval(x, y, rest...)
	server_sendval(x)
	server_sendval(y, rest...)
end

# true on success
function server_print(io::IO, i::Int)
	server_send("print", i)
	server_printtotoken(io)
	server_readbool()
end

# true on success
function server_printm(io::IO, i::Int)
	server_send("printm", i)
	server_printtotoken(io)
	server_readbool()
end

function server_printtotoken(io::IO)
	n = 0
	while true
		r = server_readline()
		r === token && return
		n == 0 || print(io, '\n')
		n += 1
		print(io, r)
	end
end

# nothing on error
function server_geterror()
	server_send("geterror")
	server_readint_check()
end

function server_numvars()
	server_send("numvars")
	server_readint()
end

# nothing on error
function server_getattr(i::Int, k::Symbol)
	server_send("getattr", i, k)
	server_readint_check()
end

# true on success
function server_setattr(i::Int, k::Symbol, x::Sendable)
	server_send("setattr", i, k)
	server_sendval(x)
	server_readtoken()
	server_readbool()
end

# true on success
function server_delattr(i::Int, k::Symbol)
	server_send("delattr", i, k)
	server_readtoken()
	server_readbool()
end

# nothing on error
function server_hasattr(i::Int, k::Symbol)
	server_send("listattrs", i)
	kk = string(k)
	r = false
	while true
	    x = server_readline()
	    x == token && break
	    if !r
		    for n in split(strip(x))
		    	if n == kk
		    		r = true
		    	end
		    end
		end
	end
	server_readbool() || (return nothing)
	r
end

# nothing on error
function server_attrisassigned(i::Int, k::Symbol)
	server_send("attrisassigned", i, k)
	server_readbool_check()
end

# nothing on error
function server_attrnames(i::Int)
	server_send("listattrs", i)
	r = Symbol[]
	while true
	    x = server_readline()
	    x == token && break
	    append!(r, map(Symbol, split(strip(x))))
	end
	server_readbool() || (return nothing)
	r
end

# true on success
function server_printerrobject(io::IO, i::Int)
	server_send("printerrobject", i)
	server_printtotoken(io)
	server_readbool()
end

# nothing on error
@generated function server_getindex(i::Int, a::Sendable...)
	isempty(a) && error("magma requires at least one index")
	length(a) ≤ 2 || error("at most two indices currently supported")
	quote
		server_send($("[$(repeat(',',length(a)-1))]"), i)
		server_sendval(a...)
		server_readint_check()
	end
end

# true on success
@generated function server_setindex(i::Int, x::Sendable, a::Sendable...)
	isempty(a) && error("magma requires at least one index")
	length(a) ≤ 2 || error("at most two indices currently supported")
	quote
		server_send($("[$(repeat(',',length(a)-1))]:="), i)
		server_sendval(x, a...)
		server_readtoken()
		server_readbool()
	end
end
