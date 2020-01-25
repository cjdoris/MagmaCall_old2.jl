mutable struct MagmaObject
	id :: Int
	function MagmaObject(::Val{:new}, id::Int)
		o = new(id)
		finalizer(o) do o
			procon[] && magassigned(o) && magdelete!(o)
		end
	end
end
export MagmaObject

struct MagmaRef
	o :: MagmaObject
end
export MagmaRef

magref(o::MagmaObject) = MagmaRef(o)
export magref;

struct MagmaIntrinsic
	name :: Symbol
end
export MagmaIntrinsic

struct MagmaType
	name :: Symbol
end
export MagmaType

struct MagmaSymbol
	name :: Symbol
end
export MagmaSymbol

magsym(name::Symbol) = MagmaSymbol(name)

const StdInt = Union{Int8, UInt8, Int16, UInt16, Int32, UInt32, Int128, UInt128, BigInt}
const SendableCollection = OrdinalRange{<:Integer,<:Integer}
const Sendable = Union{MagmaObject, Integer, Bool, AbstractString, SendableCollection, MagmaType, MagmaIntrinsic, MagmaSymbol, AbstractFloat}
const SendableArg = Union{Sendable, MagmaRef}

_id(o::MagmaObject) = getfield(o, :id)

newobj(i::Int=0) = MagmaObject(Val(:new), i)
newobj(::Nothing) = magruntimeerror()

check(x) = x
check(::Nothing) = magruntimeerror()

checkb(x::Bool) = x ? nothing : magruntimeerror()

assendable(x::Sendable) = x
assendable(x) = MagmaObject(x)

asarg(x::SendableArg) = x
asarg(x) = assendable(x)

asstdint(x::StdInt) = x
asstdint(x::Integer) = convert(BigInt, x)


abstract type MagmaException end
export MagmaException

abstract type MagmaServerError <: MagmaException end
export MagmaServerError

struct MagmaServerInvalidResponseError <: MagmaServerError
	expected
	got
end
export MagmaServerInvalidResponseError

MagmaServerInvalidResponseError(got) =
	MagmaServerInvalidResponseError(nothing, got)

function Base.showerror(io::IO, e::MagmaServerInvalidResponseError)
	print(io, typeof(e))
	if e.expected !== nothing
		print(io, ": expected $(e.expected)")
		if e.got !== nothing
			print(io, ", got $(repr(e.got))")
		end
	elseif e.got !== nothing
		print(io, ": got $(repr(e.got))")
	end
end

struct MagmaNotAssignedError <: MagmaException end
export MagmaNotAssignedError

struct MagmaRuntimeError <: MagmaException
	err :: MagmaObject
end
export MagmaRuntimeError

MagmaRuntimeError() = MagmaRuntimeError(newobj(server_geterror()))

function Base.showerror(io::IO, e::MagmaRuntimeError)
	print(io, typeof(e), ": ")
	checkb(server_printerrobject(io, id(e.err)))
end

magruntimeerror(args...) = throw(MagmaRuntimeError(args...))

