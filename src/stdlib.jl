INTRINSICS = [
	(:Parent, 1, 1),
	(:Integers, "*", 1),
	(:IntegerRing, "*", 1),
	(:Rationals, 0, 1),
	(:RationalField, 0, 1),
	(:FiniteField, "*", 1) => (gen=true,),
	(:PolynomialRing, "*", 1) => (gen=true,),
]

function declare_intrinsic(mdl, n, a, r; doexport=true, gen=false)
    f = Symbol(:mag, n)
    ni = MagmaIntrinsic(n)
    refs = Set{Int}()
    if a isa Int
    	cargs = oargs = [gensym() for i in 1:a]
    elseif a=="*"
    	cargs = oargs = [:(args...)]
    else
    	cargs = []
    	oargs = []
    	for (i,a) in enumerate(a)
    		x = gensym()
    		if a=='.'
    			push!(cargs, x)
    			push!(oargs, x)
    		elseif a=='~'
    			push!(cargs, :($x::MagmaRef))
    			push!(oargs, x)
    			push!(refs, i)
    		end
    	end
    end
    g = gensym()
    @eval mdl $f($(cargs...); opts...) =
    	magcall($(Val(r)), $ni, $(oargs...); opts...)
    gen && @eval mdl $f($g::Union{Symbol,Tuple{Vararg{Symbol}}}, $(cargs...); opts...) =
    	magcallg($ni, $g, $(oargs...); opts...)
    doexport && @eval mdl export $f
end

for x in INTRINSICS
	if x isa Pair
		declare_intrinsic(@__MODULE__, x[1]...; x[2]...)
	else
		declare_intrinsic(@__MODULE__, x...)
	end
end
