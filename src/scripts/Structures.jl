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
    mode::String
    base::Union{Float64, Tuple{Float64, Float64}}
    intervalAV::Union{Nothing, Tuple{Int64, Int64}}
end

abstract type Signal end

mutable struct QRS <: Signal
    index::Int64
    type::String
    position::Int64
    pos_end::Int64
    RR::Union{Int64, Nothing}
    AV::Union{Int64, Nothing}
    stimul_indexes::Vector{Int64}
    index_withX::Int64

    function QRS(mkpBase::API.StdMkp, _index_withX::Int64)
        _type = mkpBase.QRS_form[_index_withX]
        _pos_onset = mkpBase.QRS_onset[_index_withX]
        _pos_end = mkpBase.QRS_end[_index_withX]
        _RR = _index_withX > 1 ? _pos_onset - mkpBase.QRS_onset[_index_withX - 1] : nothing

        return new(0, _type, _pos_onset, _pos_end, _RR, nothing, Int64[], _index_withX)
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
    unrelized::Bool = false
end

@kwdef mutable struct MalfunctionsDDD <: Malfunctions
    normal::Bool = false
    oversensingV::Bool = false
    undersensingV::Bool = false
    oversensingA::Bool = false
    undersensingA::Bool = false
    exactlyUndersensingA::Bool = false
    oversensingAV::Bool = false
    noAnswerV::Bool = false
    unrelizedV::Bool = false
end

mutable struct Stimul <: Signal
    index::Int64
    type::String
    position::Int64
    QRS_index::Int64
    malfunction::Malfunctions
    stimulVerification::Union{Nothing, String}
    hasMalfunctions::Bool

    function Stimul(mkpBase::API.StdMkp, _index::Int64, QRSes::Vector{QRS}, mode::String, fs::Float64)
        _type = "U"
        # _type = mkpBase.stimtype[_index]
        _position = mkpBase.stimpos[_index]
        _QRS_index = findQRS(_position, QRSes, fs).index
        
        if mode[1:3] == "VVI"
            _malfunction = MalfunctionsVVI()
            _type = "V"
        elseif mode[1:3] == "AAI"
            _malfunction = MalfunctionsAAI()
            _type = "A"
        else
            _malfunction = MalfunctionsDDD()
        end

        return new(_index, _type, _position, _QRS_index, _malfunction, _type, false)
    end
end

function findQRS(stimulPosition::Int64, QRSes::Vector{QRS}, fs::Float64)
    errb = floor(Int, 0.030 * fs)

    for (i, pos) in enumerate(getproperty.(QRSes, :position))
        if pos + errb >= stimulPosition
            return QRSes[i]
        end
    end
    return QRSes[end]
end

function checkQRS(stimuls::Vector{Stimul}, QRSes::Vector{QRS})
    for stimul in stimuls
        QRSi = stimul.QRS_index

        if QRSi > 1 && (stimul.position in QRSes[QRSi - 1].position:QRSes[QRSi - 1].pos_end)
            stimul.QRS_index -= 1
        end
    end
    
    return stimuls
end

function mkpSignals(mkpBase::API.StdMkp, rec::EcgRecord)
    n = length(mkpBase.QRS_form)
    _QRSes = QRS[]
    j = 1
    for i in 1:n
        _QRS = QRS(mkpBase, i)
        if _QRS.type != "X"
            _QRS.index = j
            push!(_QRSes, _QRS)
            j += 1
        end
    end

    n = length(mkpBase.stimtype)
    _stimuls = Vector{Stimul}(undef, n)
    # stimulForms = classify_spikes
    for i in 1:n
        _stimuls[i] = Stimul(mkpBase, i, _QRSes, rec.mode, rec.fs)
        push!(_QRSes[_stimuls[i].QRS_index].stimul_indexes, i)
    end

    @info rec.mode
    rec.base = checkBase(_stimuls, rec.base, rec.mode)
    if rec.mode[1:3] == "DDD"
        _stimuls = checkQRS(_stimuls, _QRSes)

        stimtype = stimul_type(mkpBase.stimpos, mkpBase.QRS_onset, floor(Int, 0.25 * rec.fs), floor(Int, 0.03 * rec.fs))
        for (i, stimul) in enumerate(_stimuls)
            stimul.type = stimtype[i]
        end

        if isnothing(rec.intervalAV)
            rec.intervalAV = countingAV(_stimuls)
            @info rec.intervalAV
        end
    end

    return _QRSes, _stimuls
end

function checkBase(stimuls::Vector{Stimul},
    base::Union{Float64, Tuple{Float64, Float64}},
    mode::String
)
    CC = CCArraySpawn(getproperty.(stimuls, :position))
    _base = mediana(filter(!isnothing, CC))

    if mode[1:3] == "DDD"
        CC = filter(x -> !(x in (_base - 200):(_base + 200)), CC)
        if length(CC) > 0
            _base += mediana(CC)
        end
    end

    if length(mode) == 4
        _base = 1000 / _base * 60
        _base = round(_base / 5) * 5
        _base = 60 / _base * 1000
        return convert(Float64, _base)
    end

    if length(base) == 1
        base = base[1]
    else
        base = abs(base[1] - _base) < abs(base[2] - _base) ? base[1] : base[2]
    end

    return base
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

function CCArraySpawn(_stimpos::Vector{Int64})
    n = length(_stimpos) - 1

    _CC = zeros(n)
    for i in 1:n
        _CC[i] = _stimpos[i + 1] - _stimpos[i]
    end
    
    return _CC
end