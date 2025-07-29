function analyzeAAI(stimuls::Vector{Stimul},
    QRSes::Vector{QRS}, base::Float64, fs::Float64
)
    curQRS = QRSes[stimul.QRS_index]
    prevQRS = stimul.QRS_index > 1 ? QRSes[stimul.QRS_index - 1] : nothing

    for stimul in stimuls
        if satisfyCheck(curQRS, prevQRS)
            stimul.type = "AR"

            interval50 = MS2P.((base - MS50, base + MS50), fs)

            stimul.malfunction.normal = normalCheck(stimul)

            stimul.malfunction.undersensing = undersensingCheck(stimul)

            stimul.malfunction.exactlyUndersensing = exactlyUndersensingCheck(stimul)

            stimul.malfunction.oversensing = oversensingCheck(stimul)
        else
            stimul.type = "U"
        end
    end
end

function normalCheck(stimul::Stimul, stimuls::Vector{Stimul},
    curQRS::QRS, prevQRS::Union{Nothing, QRS},
    interval::Tuple{Int64, Int64}, base::Float64, fs::Float64
)
    ABefore = findStimulBefore(stimul.index, stimuls, 'A')
    if (!isnothing(ABefore) && 
        ABefore.QRS_index == curQRS.index &&
        ABefore.malfunction.normal
    )
        return false
    end

    if isInsideInterval(stimul, ABefore, interval)
        return true
    end

    if isMore(stimul, prevQRS, MS2P(base - MS200, fs))
        return true
    end

    AAfter = findStimulAfter(stimul.index, stimuls, 'A')
    if isInsideInterval(stimul, AAfter, interval)
        return true
    end

    return false
end

function undersensingCheck(stimul::Stimul, QRSes::Vector{QRS},
    base::Float64, fs::Float64
)
    if stimul.malfunction.normal
        return false
    end

    SAWB = findComplexBefore(stimul, QRSes, "SAWB")
    return isInsideInterval(stimul, SAWB, MS2P.((0, base - MS300), fs))
end

function exactlyUndersensingCheck(stimul::Stimul,
    stimuls::Vector{Stimul}, interval::Tuple{Int64, Int64}
)
    if !stimul.malfunction.undersensing
        return false
    end

    stimulBefore = findStimulBefore(stimul.index, stimuls)
    return isInsideInterval(stimul, stimulBefore, interval)
end

function oversensingCheck(stimul::Stimul, stimuls::Vector{Stimul},
    prevQRS::Union{Nothing, QRS}, base::Float64, fs::Float64
)
    if stimul.malfunction.oversensing
        return false
    end

    if !isnothing(prevQRS) && prevQRS.type[1] in "SAWB"
        if isMore(stimul, prevQRS, MS2P(base - MS300, fs))
            return true
        end

        ABefore = findStimulBefore(stimul, stimuls, 'A')
        if (!isnothing(ABefore) &&
            ABefore.QRS_index == prevQRS.index &&
            isMore(stimul, ABefore, MS2P(base + MS60, fs))
        )
            return true
        end
    end

    return false
end

function noAnswerCheck(stimul::Stimul, )
    
end

# TODO: доделать AAI, проверить