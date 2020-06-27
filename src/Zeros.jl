module Zeros

export Zero, testzero, One, testone

 "A type that stores no data, and holds the value zero."
struct Zero <: Integer
end

"A type that stores no data, and holds the value one."
struct One <: Integer
end

const StaticBool = Union{Zero, One}

Base.promote_rule(::Type{<:StaticBool}, ::Type{T}) where {T<:Number} = T
Base.promote_rule(::Type{<:StaticBool}, ::Type{T}) where {T<:Real} = T
Base.promote_rule(::Type{<:StaticBool}, ::Type{Complex{T}}) where {T<:Real} = Complex{T}
Base.promote_rule(::Type{<:StaticBool}, ::Type{Bool}) = Bool
Base.promote_rule(::Type{<:StaticBool}, ::Type{<:StaticBool}) = Bool

Base.convert(::Type{T}, ::Zero) where {T<:Number} = zero(T)
Base.convert(::Type{T}, ::One) where {T<:Number} = one(T)

# Why are these needed ???
(::Type{T})(::Zero) where {T<:Number} = zero(T)
(::Type{T})(::One) where {T<:Number} = one(T)

#disambig
Base.Integer(::Zero) = zero(Integer) # Int(0)
Base.Integer(::One) = one(Integer) # Int(1)

Zero(x::Number) = iszero(x) ? Zero() : throw(InexactError(:Zero, Zero, x))
One(x::Number) = isone(x) ? One() : throw(InexactError(:One, One, x))

# disambig
Zero(::Zero) = Zero()
One(::One) = One()

Base.AbstractFloat(::Zero) = 0.0
Base.AbstractFloat(::One) = 1.0

Base.zero(::StaticBool) = Zero()
Base.zero(::Type{<:StaticBool}) = Zero()
Base.one(::StaticBool) = One()
Base.one(::Type{<:StaticBool}) = One()

Base.Complex(x::Real, ::Zero) = x

# Loop over types in order to make methods specific enough to avoid ambiguities.
for T in (Number, Real, Rational, Integer, Complex, Complex{Bool})
    Base.:+(x::T, ::Zero) = x
    Base.:+(::Zero, x::T) = x
    Base.:-(x::T, ::Zero) = x
    Base.:-(::Zero, x::T) = -x
    Base.:*(::T, ::Zero) = Zero()
    Base.:*(::Zero, ::T) = Zero()
    Base.:/(::Zero, ::T) = Zero()
    Base.:/(::T, ::Zero) = throw(DivideError())
    Base.:*(x::T, ::One) = x
    Base.:*(::One, x::T) = x
end

# Division sometimes returns a different type from the arguments, e.g. for Int/Int.
Base.:/(x::AbstractFloat, ::One) = x

# Loop over rounding modes in order to make methods specific enough to avoid ambiguities.
for R in (RoundingMode, RoundingMode{:Down}, RoundingMode{:Up}, Union{RoundingMode{:Nearest}, RoundingMode{:NearestTiesAway}, RoundingMode{:NearestTiesUp}})
    Base.div(x::Integer, ::One, ::R) = x
end

# These functions are intentionally not type-stable.
"Convert to Zero() if equal to zero. (Use immediately before calling a function.)"
testzero(x::Number) = iszero(x) ? Zero() : x
"Convert to One() if equal to one. (Use immediately before calling a function.)"
testone(x::Number) = isone(x) ? One() : x

# This functions give a strange "of_sametype" error. (See int.jl)
# Hence we overload them all, even when result is not One() or Zero()
for op in (:+, :-, :*, :&, :|, :xor)
    for (T1,x) in ((:Zero, 0), (:One, 1))
        for (T2,y) in ((:Zero, 0), (:One, 1))
            val = @eval($op($x,$y))
            val = testzero(val)
            val = testone(val)
            @eval Base.$op(::$T1, ::$T2) = $val
        end
    end
end

Base.:-(::Zero) = Zero()
Base.:-(::One) = -1

Base.:/(::Zero, ::Zero) = throw(DivideError())
Base.:/(::One, ::One) = One()

# Disambig
Base.:/(::One, ::Zero) = throw(DivideError())
Base.:/(::Zero, ::One) = Zero()

Base.:<(::T,::T) where {T<:StaticBool} = false
Base.:<=(::T,::T) where {T<:StaticBool} = true

Base.ldexp(::Zero, ::Integer) = Zero()
Base.copysign(::Zero,::Real) = Zero()
Base.flipsign(::Zero,::Real) = Zero()
Base.modf(::Zero) = (Zero(), Zero())

# Alerady working due to default definitions:
# ==, !=, abs, isinf, isnan, isinteger, isreal, isimag,
# signed, unsigned, float, big, complex, isodd, iseven

for op in [:sign, :round, :floor, :ceil, :trunc, :significand]
    @eval Base.$op(::Zero) = Zero()
    @eval Base.$op(::One) = One()
end

Base.log(::One) = Zero()
Base.exp(::Zero) = One()
Base.sin(::Zero) = Zero()
Base.cos(::Zero) = One()
Base.tan(::Zero) = Zero()
Base.asin(::Zero) = Zero()
Base.atan(::Zero) = Zero()
Base.sinpi(::Zero) = Zero()
Base.sinpi(::One) = Zero()
Base.cospi(::Zero) = One()
Base.sinh(::Zero) = Zero()
Base.cosh(::Zero) = One()
Base.tanh(::Zero) = Zero()
Base.sqrt(::One) = One()
Base.sqrt(::Zero) = Zero()

# ^ has a lot of very specific methods in Base....
for T in (Float16, Float32, Float64, BigFloat, AbstractFloat, Rational, Complex{<:AbstractFloat}, Complex{<:Integer}, Integer, BigInt)
    Base.:^(::T, ::Zero) = One()
end

# # Avoid promotion of triplets
# for op in [:fma :muladd]
#     @eval $op(::Zero, ::Zero, ::Zero) = Zero()
#     for T in (Real, Integer)
#         @eval $op(::Zero, ::$T, ::Zero) = Zero()
#         @eval $op(::$T, ::Zero, ::Zero) = Zero()
#         @eval $op(::Zero, x::$T, y::$T) = convert(promote_type(typeof(x),typeof(y)),y)
#         @eval $op(x::$T, ::Zero, y::$T) = convert(promote_type(typeof(x),typeof(y)),y)
#         @eval $op(x::$T, y::$T, ::Zero) = x*y
#         @eval $op(::One, x::$T, y::$T) = x+y
#         @eval $op(x::$T, ::One, y::$T) = x+y
#     end
# end

for op in [:mod, :rem], T in (:Real, :Rational)
  @eval Base.$op(::Zero, ::$T) = Zero()
end
Base.mod(::Zero, ::Zero) = throw(DivideError()) # disambig
Base.rem(::Zero, ::Zero) = throw(DivideError()) #
Base.mod(::One, ::One) = Zero()
Base.rem(::One, ::One) = Zero()

# Sum up arrays of One() to Int
Base.reduce_empty(::typeof(Base.add_sum), ::Type{One}) = zero(Int)
Base.reduce_first(::typeof(Base.add_sum), x::One) = Int(x)

# Sum up arrays of Zero() to Zero()
Base.add_sum(::Zero, ::Zero) = Zero()

# Display Zero() as `𝟎` ("mathematical bold digit zero")
# so that it looks slightly different from `0` (and same for One()).
Base.show(io::IO, ::Zero) = print(io, "𝟎") # U+1D7CE
Base.show(io::IO, ::One) = print(io, "𝟏") # U+1D7CF

Base.string(z::StaticBool) = Base.print_to_string(z)

Base.Checked.checked_abs(x::StaticBool) = x
Base.Checked.checked_mul(x::StaticBool, y::StaticBool) = x*y
Base.Checked.mul_with_overflow(x::StaticBool, y::StaticBool) = (x*y, false)
Base.Checked.checked_add(x::StaticBool, y::StaticBool) = x+y

if VERSION < v"1.2"
    # Disambiguation needed for older Julia versions
    Base.copysign(::Zero, x::Unsigned) = Zero()
    Base.flipsign(::Zero, x::Unsigned) = Zero()
end

include("pirate.jl")

end # module
