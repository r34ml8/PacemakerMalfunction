function analyzeAAI(stimuls::Vector{Stimul},
    QRSes::Vector{QRS}, base::Float64, fs::Float64
)
    interval50 = MS2P.((base - MS50, base + MS50), fs)    

    for stimul in stimuls
        curQRS = QRSes[stimul.QRS_index]
        prevQRS = stimul.QRS_index > 1 ? QRSes[stimul.QRS_index - 1] : nothing

        if satisfyCheck(curQRS, prevQRS)
            stimul.type = "AR"

            stimul.malfunction.normal = normalCheckA(stimul, stimuls, curQRS, prevQRS, interval50, base, fs)
            stimul.malfunction.undersensing = undersensingCheckA(stimul, QRSes, base, fs)
            stimul.malfunction.exactlyUndersensing = exactlyUndersensingCheckA(stimul, stimuls, interval50)
            stimul.malfunction.oversensing = oversensingCheckA(stimul, stimuls, prevQRS, base, fs)
            if stimul.index > 1
                stimuls[stimul.index - 1].malfunction.noAnswer = noAnswerCheckA(stimul, stimuls, curQRS)
            end
            stimul.malfunction.unrelized = unrelizedCheckA(stimul, curQRS, prevQRS)
        else
            stimul.type = "U"
        end
    end
end

function normalCheckA(stimul::Stimul, stimuls::Vector{Stimul},
    curQRS::QRS, prevQRS::Union{Nothing, QRS},
    interval::Tuple{Int64, Int64}, base::Float64, fs::Float64
)
    ABefore = findStimulBefore(stimul.index, stimuls, 'A')
    if (inQRS(curQRS.index, ABefore) &&
        ABefore.malfunction.normal
    )
        # stimul.type = "A"
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

    # stimul.type = "A"
    return false
end

function undersensingCheckA(stimul::Stimul, QRSes::Vector{QRS},
    base::Float64, fs::Float64
)
    if stimul.malfunction.normal
        return false
    end

    SAWB = findQRSBefore(stimul, QRSes, "SAWB")
    res = isInsideInterval(stimul, SAWB, MS2P.((0, base - MS300), fs))
    
    stimul.hasMalfunctions = stimul.hasMalfunctions || res
    return res
end

function exactlyUndersensingCheckA(stimul::Stimul,
    stimuls::Vector{Stimul}, interval::Tuple{Int64, Int64}
)
    if !stimul.malfunction.undersensing
        return false
    end

    stimulBefore = findStimulBefore(stimul.index, stimuls)

    res = isInsideInterval(stimul, stimulBefore, interval)
    
    stimul.hasMalfunctions = stimul.hasMalfunctions || res
    return res
end

function oversensingCheckA(stimul::Stimul, stimuls::Vector{Stimul},
    prevQRS::Union{Nothing, QRS}, base::Float64, fs::Float64
)
    if stimul.malfunction.normal
        return false
    end

    if !isnothing(prevQRS) && prevQRS.type[1] in "SAWB"
        if isMore(stimul, prevQRS, MS2P(base - MS300, fs))
            stimul.hasMalfunctions = true
            return true
        end

        ABefore = findStimulBefore(stimul.index, stimuls, 'A')
        if (inQRS(prevQRS.index, ABefore) &&
            isMore(stimul, ABefore, MS2P(base + MS60, fs))
        )
            stimul.hasMalfunctions = true
            return true
        end
    end

    return false
end

function noAnswerCheckA(stimul::Stimul, stimuls::Vector{Stimul},
    curQRS::QRS)
    if (stimul.malfunction.normal || stimul.hasMalfunctions)
        stimulBefore = findStimulBefore(stimul.index, stimuls)
        if inQRS(curQRS.index, stimulBefore)
            stimuls[stimulBefore.index].type = "AN"

            return true
        end
    end

    return false
end

# проверки на нереализованность не было в алгоритме
function unrelizedCheckA(stimul::Stimul, curQRS::QRS,
    prevQRS::Union{Nothing, QRS}
)
    mid = prevQRS.pos_end
    mid += (curQRS.position - prevQRS.pos_end) * 0.25
    if prevQRS.position <= stimul.position <= mid
        stimul.type = "A"

        return true
    end

    return false
end