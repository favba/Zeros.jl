__precompile__()
module Zeros

using StaticNumbers

import Base: +, -, *, /, <, >, <=, >=, fma, muladd, mod, rem, modf,
     ldexp, copysign, flipsign, sign, round, floor, ceil, trunc,
     promote_rule, convert, show, significand, string,
     AbstractFloat, Integer, Complex, real, imag

export Zero, testzero, zero!

"A type that stores no data, and holds the value zero."
const Zero = StaticInteger{0}
"A type that stores no data, and holds the value one."
const One = StaticInteger{1}
"A type that stores no data, and holds the value minus one."
const MinusOne = StaticInteger{-1}

Zero(x::Number) = iszero(x) ? Zero() : throw(InexactError(:Zero, Zero, x))

AbstractFloat(::Zero) = 0.0

Complex(x::Real, ::Zero) = x

# Methods involving only the above-defined constants.
include("generated.jl")

# Loop over types in order to make methods specific enough to avoid ambiguities.
for T in (Number, Real, Integer, Complex, Complex{Bool})
    Base.:+(x::T,::Zero) = x
    Base.:+(::Zero,x::T) = x
    Base.:-(x::T,::Zero) = x
    Base.:-(::Zero,x::T) = -x
    Base.:*(::T,::Zero) = Zero()
    Base.:*(::Zero,::T) = Zero()
    Base.:/(::Zero, ::T) = Zero()
    Base.:/(::T, ::Zero) = throw(DivideError())
end

Base.:/(::Zero, ::Zero) = throw(DivideError()) # disambiguation

ldexp(::Zero, ::Integer) = Zero()
copysign(::Zero,::Real) = Zero()
flipsign(::Zero,::Real) = Zero()
modf(::Zero) = (Zero(), Zero())

# Alerady working due to default definitions:
# ==, !=, abs, isinf, isnan, isinteger, isreal, isimag,
# signed, unsigned, float, big, complex, isodd, iseven

for op in [:round, :floor, :ceil, :trunc, :significand], T in (:Zero, :One, :MinusOne)
  @eval $op(::$T) = $T()
end

# Avoid promotion of triplets
for op in [:fma :muladd]
    @eval $op(::Zero, ::Zero, ::Zero) = Zero()
    for T in (Real, Integer)
        @eval $op(::Zero, ::$T, ::Zero) = Zero()
        @eval $op(::$T, ::Zero, ::Zero) = Zero()
        @eval $op(::Zero, x::$T, y::$T) = convert(promote_type(typeof(x),typeof(y)),y)
        @eval $op(x::$T, ::Zero, y::$T) = convert(promote_type(typeof(x),typeof(y)),y)
        @eval $op(x::$T, y::$T, ::Zero) = x*y
    end
end

for op in [:mod, :rem]
  @eval $op(::Zero, ::Real) = Zero()
end

# Display Zero() as `0̸` (unicode "zero with combining long solidus overlay")
# so that it looks slightly different from `0`.
show(io::IO, ::Zero) = print(io, "0̸")
string(z::Zero) = Base.print_to_string(z)

# Display Array{Zero} without printing the actual zeros.
show(io::IO, x::Array{Zero,N}) where {N} = show(io, MIME"text/plain", x)
function show(io::IO, ::MIME"text/plain", x::Array{Zero,N}) where {N}
    join(io, map(dec, size(x)), "x")
    print(io, " Array{Zero,", N, "}")
end

# This function is intentionally not type-stable.
"Convert to Zero() if zero. (Use immediately before calling a function.)"
testzero(x::Number) = x==zero(x) ? Zero() : x

"Fill an array with zeros."
zero!(a::Array{T}) where T = fill!(a, Zero())

end # module
