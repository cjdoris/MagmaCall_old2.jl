# MagmaCall.jl
Call Magma code from Julia.

## Install

Install like so: `using Pkg; Pkg.add("https://github.com/cjdoris/MagmaCall.jl")`

You need to have Magma already installed, with the `magma` executable in your PATH.

## User Guide

The type `MagmaObject` is used to wrap a Magma value. Basic Julia types like integers, floats, strings, ranges, arrays and sets can be converted to their Magma equivalent. From these you can build up more complicated structures.

You can interact with these objects in the usual ways: arithmetic operations, comparisons (`x<y` becomes `x le y`), iteration, indexing (`x[i]` and `x[i,j]`), properties (```x.k``` becomes ```x`k```) and so forth.

### Function/procedure calls
Since there is no syntactic difference between a function call and a procedure call, this information must be provided by the user. The following functions exist for making calls:
```julia
magcall(N, f, ...; ...)
magcallp(f, ...; ...)
magcallf(f, ...; ...)
magcallf2(f, ...; ...)
magcallf3(f, ...; ...)
magcallb(f, ...; ...)
magcalli(f, ...; ...)
magcallg(f, vs, ...; ...)
```
The most general is the first form, where `N` is the number of return values. When `N=0` this is a procedure call, which returns `nothing`. Otherwise this is a function call, and returns one return value when `N=1`, or returns a tuple of return values when `N>1`. There are shorthands `magcallp` for `N=0`, `magcallf` for `N=1`, `magcallf2` for `N=2` and so on. The keyword argument `_stdout` controls where Magma's output is redirected.

If `f` is a symbol, it is interpreted as the name of an intrinsic.

To pass an argument `x` by reference to a procedure, wrap it with `magref(x)`.

Also `magcallb` is like `magcallf` but assumes the function returns a boolean, and converts it to a Julia `Bool`. Similarly `magcalli` converts the return value to a Julia `Int`.

Finally, `magcallg` is like `magcallf` but takes as a second argument a symbol or n-tuple of symbols. If `magcallf` would have returned `R` (e.g. a ring), then `magcallg` assigns the names `vs` to `R`, then returns a tuple of `R` and the corresponding generators. Hence the following is a compact way to generate a polynomial ring and give a name to its generator:
```juliarepl
julia> R, x = magcallg(:PolynomialRing, :x, K)
```

### Containers

```julia
magseq([x]; [universe])
magset([x]; [universe])
maglist([x])
```
These return a new Magma sequence, set or list. It will be empty unless `x` is given. Optionally the universe of the container can be specified.


## How does this work?

Since Magma does not have a programmatic API, we communicate with it through `stdin` and `stdout`. A "server" runs in Magma to take in commands and return information. This server is defined in `server.mag`, which is loaded in `__init__`, then started by calling `__jl_server_start()` in Magma.

This server has some state, which mainly consists of a lookup table mapping unique integer ids to Magma values. These ids are what are also stored Julia-side in a `MagmaObject`. By sending commands to the server, we can create new values, look up attributes, call intrinsics, print stuff out, and so forth. When a `MagmaObject` is garbage-collected, the corresponding value in Magma is deleted.

Because communication is done via IO streams, each individual operation has quite a bit of overhead (e.g. around 0.4ms on my machine). Hence this package will be extremely slow if you try to do anything with tight loops, but is fine for interactive use or for using Julia for high-level control.
