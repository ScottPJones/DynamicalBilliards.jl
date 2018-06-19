################################################################################
##
##  This file contains functions to transform to and from boundary coordinates
##  which are required for `boundarymap` and `phasespace_portion`
##
################################################################################

export arcintervals, arclength, real_coordinates

#this function only exists because incidence_angle from raysplitting.jl only works
#if you pass the particle *before* collision, which I cannot do because of bounce!
function reflection_angle(p::AbstractParticle{T}, a::Obstacle{T})::T where {T}
    n = normalvec(a, p.pos)
    inverse_dot = clamp(dot(p.vel, n), -1.0, 1.0)
    φ = acos(inverse_dot)
    if cross2D(p.vel, n) < 0
        φ *= -1
    end
    return φ
end


################################################################################
## Arclengths
################################################################################

## BILLIARD-LEVEL FUNCTIONS ####################################################

"""
    arcintervals(bd::Billiard)
Generate an array of `SVector`s, with the `i`th `SVector` containing the arc
length intervals corresponding to the `i`th `Obstacle` in `bd`.

Used by [`boundarymap`](@ref) to compute arc lengths.
"""
function arcintervals(bd::Billiard{T, D}) where {T, D}
    intervals = Vector{SVector{2,T}}(undef, D)
    current = zero(T)
    for i ∈ 1:D
        l = totallength(bd[i]) + current
        intervals[i] = SVector{2,T}(current, l)
        current = l
    end
    return intervals
end

## OBSTACLE-LEVEL FUNCTIONS ####################################################

"""
    arclength(p::AbstractParticle, o::Obstacle)
    arclength(pos::SVector{2,T}, o::Obstacle)
Returns the boundary coordinate of the particle on the obstacle,
assuming that the particle position is on the obstacle.

The boundary coordinate is measured as:
* the distance from start point to end point in `Wall`s
* the arc length measured counterclockwise from the open face in `Semicircle`s
* the arc length measured counterclockwise from the rightmost point 
  in `Circular`s
"""
arclength(p::AbstractParticle, o) = arclength(p.pos, o)

# walls
arclength(pos::SV, o::Wall) = norm(pos - o.sp)

# semicircles
function arclength(pos::SV{T}, o::Semicircle{T}) where {T<:AbstractFloat}
    #project pos on open face
    chrd = SV{T}(-o.facedir[2],o.facedir[1]) 
    d = (pos - o.c)/o.r
    x = dot(d, chrd)
    r =  acos(clamp(x, -1, 1))*o.r
    return r
end


# other circulars
function arclength(pos::SV{T}, o::Circular{T}) where {T<:AbstractFloat}
    d = (pos - o.c)/o.r
    r = acos(clamp(d[1], -1, 1))*o.r
    return r
end


################################################################################
## real_coordinates
################################################################################

## BILLIARD-LEVEL FUNCTIONS ####################################################

"""
    real_coordinates(ξ, sφ, bd::Billiard; return_obstacle = false)
Converts Birkhoff coordinates `ξ` and `sφ` on the Billiard `bd` to real space 
coordinates. 
Returns position and velocity vectors in real space. If `return_obstacle` is 
the index of the obstacle corresponding to this position is also returned.
"""
function real_coordinates(ξ, sφ, bd::Billiard{T};
                          return_obstacle::Bool = false) where T
    
    abs(sφ) > 1 && throw(DomainError(sφ, "|sin φ| must not be larger than 1"))
    lower = zero(T)
    upper = lower
    for (i, obst) ∈ enumerate(bd)
        
        upper = lower + totallength(obst)

        if ξ <= upper
            pos = real_pos(ξ - lower, obst)
            #calculate velocity
            cφ = cos(asin(sφ))
            n = normalvec(obst, pos)
            vel = SV{T}(-n[1]*cφ + n[2]*sφ, -n[1]*sφ - n[2]*cφ)
            return return_obstacle ? (pos, vel, i) : (pos, vel)
        end
        lower = upper

    end

    throw(DomainError(ξ ,"ξ is too large for this billiard!"))
end

## OBSTACLE-LEVEL FUNCTIONS ####################################################


#walls
"""
    real_pos(ξ, o::Obstacle)
Converts the arclength `ξ` relative to the Obstacle `o` into a real space 
position vector. 
"""
real_pos(ξ, o::Wall) = o.sp + ξ*normalize(o.ep - o.sp)

#semicircles
function real_pos(ξ, o::Semicircle{T}) where T
    sξ, cξ = sincos(ξ/o.r)
    chrd = SV{T}(-o.facedir[2], o.facedir[1])
    return o.c - o.r*(sξ*o.facedir - cξ*chrd)
end

#other circulars
real_pos(ξ, o::Circular{T}) where T = o.c .+ o.r * SV{T}(cossin(ξ/o.r))

