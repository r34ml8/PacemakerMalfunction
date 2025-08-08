function MS2P(t::Real, fs::Float64)
    return floor(Int, t * fs / 1000)
end

function P2MS(p::Int64, fs::Float64)
    return p * 1000 / fs
end

function satisfyCheck(curQRS::QRS, prevQRS::Union{Nothing, QRS})
    if (curQRS.type == "Z" ||
        !isnothing(prevQRS) && prevQRS.type == "Z"
    )
        return false
    end

    return true
end 

function countingAV(stimuls::Vector{Stimul})
    stimulBefore = stimuls[1]
    n = length(stimuls)
    AV = Int64[]
    
    for i in 2:n
        if stimuls[i].QRS_index == stimulBefore.QRS_index
            push!(AV, stimuls[i].position - stimulBefore.position)
        end
        stimulBefore = stimuls[i]
    end
    
    _AV = length(AV) > 0 ? mediana(AV) : 0
    return (_AV, _AV)
end

function ST(curQRS::QRS)
    excess = curQRS.pos_end - curQRS.pos_end
    excess = excess > 120 ? excess - 120 : 0
    return round(curQRS.pos_end + 0.42 * sqrt(curQRS.RR) - excess)
end

function isInsideInterval(stimul::Signal, signal::Union{Signal, Nothing}, interval::Tuple{<:Real, <:Real})
    if !isnothing(signal) && (interval[1] <= abs(stimul.position - signal.position) <= interval[2])
        return true
    end

    return false
end

function isMore(stimul::Signal, signal::Union{Signal, Nothing}, value::Real)
    if !isnothing(signal) && (abs(stimul.position - signal.position) > value)
        return true
    end

    return false
end

function findStimulBefore(stimul_index::Int64, stimuls::Union{Nothing, Vector{Stimul}}, typeCh::Char=' ')
    for j in (stimul_index - 1):-1:1
        if (
            typeCh == ' ' ||
            typeCh == 'V' && VCheck(stimuls[j]) ||
            typeCh == 'A' && ACheck(stimuls[j])
        )
            return stimuls[j]
        end
    end

    return nothing
end

function findStimulAfter(stimul_index::Int64, stimuls::Union{Nothing, Vector{Stimul}}, typeCh::Char=' ')
    for j in (stimul_index + 1):length(stimuls)
        if (
            typeCh == ' ' ||
            typeCh == 'V' && VCheck(stimuls[j]) ||
            typeCh == 'A' && ACheck(stimuls[j])
        )
            return stimuls[j]
        end
    end
    return nothing
end

function VCheck(stimul::Stimul)
    return stimul.type in ("V", "VR") ? true : false
end

function ACheck(stimul::Stimul)
    return stimul.type in ("A", "AR") ? true : false
end

function mediana(vec)
    med = vec[1]

    dict = Dict(i => 0 for i in unique(vec))
    for elem in vec
        dict[elem] += 1
        med = dict[elem] == maximum(values(dict)) ? elem : med
    end
    return med
end

function findQRSBefore(stimul::Stimul, QRSes::Vector{QRS}, typeStr::String)
    for j in (stimul.QRS_index - 1):-1:1
        if QRSes[j].type[1] in typeStr
            return QRSes[j]
        end
    end

    return nothing
end

function inQRS(QRS_i::Int64, stimul::Union{Nothing, Stimul})
    return !isnothing(stimul) && stimul.QRS_index == QRS_i ? true : false
end

function goodAV(stimul::Stimul, _QRS::QRS, rec::EcgRecord, AV50::Tuple{Int64, Int64})
    if (isnothing(_QRS.AV) ||
        _QRS.AV in AV50 ||
        isInsideInterval(stimul, _QRS, MS2P.((0, rec.intervalAV[2]), rec.fs))
    )
        return true
    end
    
    return false
end