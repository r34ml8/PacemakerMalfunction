module Stimuls

import FileUtils.StdEcgDbAPI as API
include("EcgChar.jl")

@kwdef mutable struct Stimul
    index::Int = 0
    type::String = ""
    position::Int = 0
    complex::Union{Complex, Nothing} = nothing

    function Stimul(mkpBase::API.StdMkp, _index::Int)
        _type = mkpBase.stimtype
        _position = mkpBase.stimpos
        _complex

        return new(_index, _type, _position)
    end
end

@kwdef mutable struct Complex
    index::Int = 0
    base::Int = 0
    Z::Bool = false
    pos_onset::Int = 0
    pos_end::Int = 0

    function Complex(mkpBase::API.StdMkp, _index::Int, _base::Int)
        _Z = mkpBase.QRS_form[_index] == "Z" ? true : false
        _pos_onset = mkpBase.QRS_onset
        _pos_end = mkpBase.QRS_end
        
        return new(_index, _base, _Z, _pos_onset, _pos_end)
    end
end

function FindComplex(stimulPosition::Int, complexes::Vector{Complex})
    vectorDiff = abs.(stimulPosition .- complexes.pos_onset)
    return complexes[argmin(vectorDiff)]
end

end