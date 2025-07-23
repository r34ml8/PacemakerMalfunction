module EcgChar

import FileUtils.StdEcgDbAPI as API

abstract type Signal end

mutable struct Complex <: Signal
    index::Int
    Z::Bool
    position::Int
    pos_end::Int
    RR::Union{Int, Nothing}

    function Complex(mkpBase::API.StdMkp, _index::Int)
        _Z = mkpBase.QRS_form[_index] == "Z" ? true : false
        _pos_onset = mkpBase.QRS_onset[_index]
        _pos_end = mkpBase.QRS_end[_index]
        _RR = _index > 1 ? _pos_onset - mkpBase.QRS_onset[_index - 1] : nothing

        return new(_index, _Z, _pos_onset, _pos_end, _RR)
    end
end

mutable struct Stimul <: Signal
    index::Int
    type::String
    position::Int
    complex::Complex
    satisfy::Bool
    malfunction::Malfunctions

    function Stimul(mkpBase::API.StdMkp, _index::Int, complexes::Vector{Complex}, mode::Int)
        _type = mkpBase.stimtype[_index]
        _position = mkpBase.stimpos[_index]
        _complex = findComplex(_position, complexes)

        if mode == 3
            _malfunction = MalfunctionsDDD()
        elseif mode == 2
            _malfunction = MalfunctionsAAI()
        else
            _malfunction = MalfunctionsVVI()
        end

        return new(_index, _type, _position, _complex, true, _malfunction)
    end
end

abstract type Malfunctions end

@kwdef mutable struct MalfunctionsVVI <: Malfunctions
    normal::Bool = false
    undersensing::Bool = false
    exactlyUndersensing::Bool = false
    oversensing::Bool = false
    hysteresis::Bool = false
    noAnswer::Bool = false
    unrelized::Bool = false
end

@kwdef mutable struct MalfunctionsAAI <: Malfunctions
end

@kwdef mutable struct MalfunctionsDDD <: Malfunctions
end

"""
malfunction: расшифровка битов
1 - норма
2 - гипосенсинг по желудочковому каналу
3 - точно гипосенсинг по желудочковому каналу
4 - гиперсенсинг по желудочковому каналу
5 - гистерезис
6 - желудочковый стимул без ответа
7 - нереализованный желудочковый стимул
"""

# пока тут привязка к ближайшему
# TODO: сделать привязку к ближайшему справа
function findComplex(stimulPosition::Int, complexes::Vector{Complex})
    vectorDiff = abs.(stimulPosition .- getproperty.(complexes, :position))
    return complexes[argmin(vectorDiff)]
end

mutable struct EcgRecord
    mode::Int #1 - VVI, 2 - AAI, 3 - DDD
    base::Int
    complexes::Vector{Complex}
    stimuls::Vector{Stimul}

    function EcgRecord(mkpBase::API.StdMkp, _mode::Int, _base::Int)
        n = length(mkpBase.QRS_form)
        _complexes = Vector{Complex}(undef, n)
        for i in 1:n
            _complexes[i] = Complex(mkpBase, i)
        end

        n = length(mkpBase.stimtype)
        _stimuls = Vector{Stimul}(undef, n)
        for i in 1:n
            _stimuls[i] = Stimul(mkpBase, i, _complexes, _mode)
        end
        
        return new(_mode, _base, _complexes, _stimuls)
    end
end

function findPrevComplex(stimul::Stimul, record::EcgRecord)
    i = stimul.complex.index
    return i > 1 ? record.complexes[i - 1] : nothing
end

include("MalfunctionVVI.jl")

# function BitArraySpawn(n::Int, _QRS_form::Vector{String})
#     _SAWB = BitArray(undef, n)
#     _VF = BitArray(undef, n)
#     _C = BitArray(undef, n)
    
#     for i in 1:n
#         QRS = _QRS_form[i]
#         println(QRS[1])
#         if (QRS[1] == 'V') || (QRS[1] == 'F')
#             _VF[i] = 1
#             println("true")
#         elseif QRS[1] == 'C'
#             _C[i] = 1
#         else
#             _SAWB[i] = 1
#             println("false")
#         end
#     end

#     return _SAWB, _VF, _C
# end

# function CCArraySpawn(_stimpos::Vector{Int})
#     n = length(_stimpos) - 1

#     _CC = zeros(n)
#     for i in 1:n
#         _CC[i] = _stimpos[i + 1] - _stimpos[i]
#     end
    
#     return _CC
# end

end