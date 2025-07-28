const MS15 = 15
const MS30 = 30
const MS50 = 50
const MS60 = 60
const MS70 = 70
const MS80 = 80
const MS100 = 100
const MS200 = 200
const MS300 = 300

abstract type Signal end

mutable struct Complex <: Signal
    index::Int
    type::String
    position::Int
    pos_end::Int
    RR::Union{Int, Nothing}

    function Complex(mkpBase::API.StdMkp, _index::Int)
        _type = mkpBase.QRS_form[_index]
        _pos_onset = mkpBase.QRS_onset[_index]
        _pos_end = mkpBase.QRS_end[_index]
        _RR = _index > 1 ? _pos_onset - mkpBase.QRS_onset[_index - 1] : nothing

        return new(_index, _type, _pos_onset, _pos_end, _RR)
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
    normal::Bool = false
    undersensing::Bool = false
    exactlyUndersensing::Bool = false
    oversensing::Bool = false
    noAnswer::Bool = false
end

@kwdef mutable struct MalfunctionsDDD <: Malfunctions
end

mutable struct Stimul <: Signal
    index::Int
    type::String
    position::Int
    complex::Complex
    malfunction::Malfunctions

    function Stimul(mkpBase::API.StdMkp, _index::Int, complexes::Vector{Complex}, mode::Int)
        _type = "U"
        # _type = mkpBase.stimtype[_index]
        _position = mkpBase.stimpos[_index]
        _complex = findComplex(_position, complexes)

        if mode == 3
            _malfunction = MalfunctionsDDD()
        elseif mode == 2
            _malfunction = MalfunctionsAAI()
            _type = "A"
        else
            _malfunction = MalfunctionsVVI()
            _type = "V"
        end

        return new(_index, _type, _position, _complex, _malfunction)
    end
end

function findComplex(stimulPosition::Int, complexes::Vector{Complex})
    for (i, pos) in enumerate(getproperty.(complexes, :position))
        if pos + 15 >= stimulPosition
            return complexes[i]
        end
    end
end

function baseParams(mkpBase::API.StdMkp, mode::Int)
    n = length(mkpBase.QRS_form)
    _complexes = Vector{Complex}(undef, n)
    for i in 1:n
        _complexes[i] = Complex(mkpBase, i)
    end

    n = length(mkpBase.stimtype)
    _stimuls = Vector{Stimul}(undef, n)
    stimulForms = classify_spikes
    for i in 1:n
        _stimuls[i] = Stimul(mkpBase, i, _complexes, mode::Int)
    end
    
    checkBase(_complexes)

    return _complexes, _stimuls
end

function findPrevComplex(stimul::Stimul)
    i = stimul.complex.index
    return i > 1 ? complexes[i - 1] : nothing
end

function checkBase(complexes::Vector{Complex})
    global base
    if length(base) == 1
        base = base[1]
    else
        _base = mediana(filter(!isnothing, getproperty.(complexes, :RR)))
        base = abs(base[1] - _base) < abs(base[2] - _base) ? base[1] : base[2]
    end
end

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