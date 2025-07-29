const MS15 = 15
const MS30 = 30
const MS50 = 50
const MS60 = 60
const MS70 = 70
const MS80 = 80
const MS100 = 100
const MS200 = 200
const MS300 = 300

mutable struct EcgRecord
    fs::Float64
    mode::Int64
    base::Union{Float64, Tuple{Float64, Float64}}
    intervalAV::Union{Nothing, Int64, Tuple{Int64, Int64}}
end

abstract type Signal end

mutable struct QRS <: Signal
    index::Int64
    type::String
    position::Int64
    pos_end::Int64
    RR::Union{Int64, Nothing}

    function QRS(mkpBase::API.StdMkp, _index::Int64)
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
    index::Int64
    type::String
    position::Int64
    QRS_index::Int64
    malfunction::Malfunctions

    function Stimul(mkpBase::API.StdMkp, _index::Int64, QRSes::Vector{QRS}, mode::Int64)
        _type = "U"
        # _type = mkpBase.stimtype[_index]
        _position = mkpBase.stimpos[_index]
        _QRS_index = findQRS(_position, QRSes).index

        if mode == 3
            _malfunction = MalfunctionsDDD()
        elseif mode == 2
            _malfunction = MalfunctionsAAI()
            _type = "A"
        else
            _malfunction = MalfunctionsVVI()
            _type = "V"
        end

        return new(_index, _type, _position, _QRS_index, _malfunction)
    end
end

function findQRS(stimulPosition::Int64, QRSes::Vector{QRS})
    for (i, pos) in enumerate(getproperty.(QRSes, :position))
        if pos + 15 >= stimulPosition
            return QRSes[i]
        end
    end
end

function mkpSignals(mkpBase::API.StdMkp, mode::Int64, base::Float64)
    n = length(mkpBase.QRS_form)
    _QRSes = Vector{QRS}(undef, n)
    for i in 1:n
        _QRSes[i] = QRS(mkpBase, i)
    end

    n = length(mkpBase.stimtype)
    _stimuls = Vector{Stimul}(undef, n)
    # stimulForms = classify_spikes
    for i in 1:n
        _stimuls[i] = Stimul(mkpBase, i, _QRSes, mode)
    end
    
    checkBase(_QRSes, base)

    return _QRSes, _stimuls
end

function checkBase(QRSes::Vector{QRS},
    base::Union{Float64, Tuple{Float64, Float64}}
)
    if length(base) == 1
        base = base[1]
    else
        _base = mediana(filter(!isnothing, getproperty.(QRSes, :RR)))
        base = abs(base[1] - _base) < abs(base[2] - _base) ? base[1] : base[2]
    end
end

# function BitArraySpawn(n::Int64, _QRS_form::Vector{String})
#     _SAWB = BitArray(undef, n)
#     _VF = BitArray(undef, n)
#     _C = BitArray(undef, n)
    
#     for i in 1:n
#         QRS = _QRS_form[i]
#         printInt64ln(QRS[1])
#         if (QRS[1] == 'V') || (QRS[1] == 'F')
#             _VF[i] = 1
#             printInt64ln("true")
#         elseif QRS[1] == 'C'
#             _C[i] = 1
#         else
#             _SAWB[i] = 1
#             printInt64ln("false")
#         end
#     end

#     return _SAWB, _VF, _C
# end

# function CCArraySpawn(_stimpos::Vector{Int64})
#     n = length(_stimpos) - 1

#     _CC = zeros(n)
#     for i in 1:n
#         _CC[i] = _stimpos[i + 1] - _stimpos[i]
#     end
    
#     return _CC
# end