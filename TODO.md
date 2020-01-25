- Indexed sets and multisets.

- Tuples.

- Records.

- Make communication with the server more robust.

- All the Magma operators.

- All the Magma constructors, e.g. `ideal<...>`.

- Wrap Magma intrinsics into their Julia couterparts in `base.jl`.

- Conversion from Magma to Julia.

- Move `server.mag` to a new folder `magma/` and split out the stuff replicating Julia base functionality into `base.jl`.

- Generalize the first argument to `magcall`. Instead of an integer for the number of return values, have a symbol, where each character encodes a return value: `'o'` being a `MagmaObject`, `'i'` being an integer, `'b'` being a boolean, `'_'` being ignored (more types would be easy to add). Then `magcall(:_i, :Maximum, x)` is effectively `argmax(x)` as an integer.
