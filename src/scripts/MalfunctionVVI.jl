function analyzeVVI(stimuls::Vector{Stimul},
    QRSes::Vector{QRS}, base::Float64, fs::Float64
)
    interval50 = MS2P.((base - MS50, base + MS50), fs)
    for stimul in stimuls
        curQRS = QRSes[stimul.QRS_index]
        prevQRS = stimul.QRS_index > 1 ? QRSes[stimul.QRS_index - 1] : nothing
        
        if satisfyCheck(curQRS, prevQRS)
            stimul.malfunction.normal = normalCheckV(stimul, stimuls, curQRS, prevQRS, interval50, fs)
            stimul.malfunction.undersensing = undersensingCheckV(stimul, prevQRS, base, fs)
            stimul.malfunction.exactlyUndersensing = exactlyUndersensingCheckV(stimul, stimuls, prevQRS, interval50)
            stimul.malfunction.oversensing = oversensingCheckV(stimul, stimuls, prevQRS, base, fs)
            stimul.malfunction.hysteresis = hysteresisCheckV(stimul, curQRS, prevQRS, base, fs)
            stimul.malfunction.noAnswer = noAnswerCheckV(stimul, curQRS, prevQRS, fs)
            stimul.malfunction.unrelized = unrelizedCheckV(stimul, prevQRS)
        else
            stimul.type = "U"
        end
    end 
end

function normalCheckV(stimul::Stimul, stimuls::Vector{Stimul},
    curQRS::QRS, prevQRS::QRS, interval::Tuple{Int64, Int64}, fs::Float64
)
    if !isInsideInterval(stimul, curQRS, MS2P.((0, MS70), fs))
        stimul.type = "V" # использую это условие в т.ч. как проверку на реализованность
        @info 1
        return false
    end

    stimul.type = "VR"

    VBefore = findStimulBefore(stimul.index, stimuls, 'V')
    if isInsideInterval(stimul, VBefore, interval)
        @info 2
        return true
    end

    if isInsideInterval(stimul, prevQRS, interval)
        @info 3
        return true
    end

    VAfter = findStimulAfter(stimul.index, stimuls, 'V')
    if isInsideInterval(stimul, VAfter, interval)
        @info 4
        return true
    end

    @info 5
    return false
end

function undersensingCheckV(stimul::Stimul,
    prevQRS::Union{Nothing, QRS}, base::Float64, fs::Float64
)
    if !stimul.malfunction.normal && stimul.stimulVerification == "V"
        res = isInsideInterval(stimul, prevQRS, MS2P.((MS200, base - MS300), fs))

        stimul.hasMalfunctions = stimul.hasMalfunctions || res
        return res
    end

    return false
end

function exactlyUndersensingCheckV(stimul::Stimul,
    stimuls::Vector{Stimul}, prevQRS::Union{Nothing, QRS},
    interval::Tuple{Int64, Int64}
)
    if stimul.malfunction.undersensing
        if (isInsideInterval(stimul, findStimulBefore(stimul.index, stimuls), interval) ||
            isInsideInterval(stimul, findStimulAfter(stimul.index, stimuls), interval)
        )
            stimul.hasMalfunctions = true
            return true
        end
    end

    if ((stimul.malfunction.normal || stimul.malfunction.undersensing) &&
        !isnothing(prevQRS) && !isnothing(prevQRS.RR)
        )
        interval = interval .- prevQRS.RR
        if isInsideInterval(stimul, prevQRS, interval)
            stimul.hasMalfunctions = true
            return true
        end
    end

    return false
end

function oversensingCheckV(stimul::Stimul, stimuls::Vector{Stimul},
    prevQRS::Union{Nothing, QRS}, base::Float64, fs::Float64
)
    if !stimul.malfunction.normal
        if isMore(stimul, prevQRS, MS2P(base + MS300, fs))
            VBefore = findStimulBefore(stimul, stimuls, 'V')

            if (isMore(stimul, VBefore, MS2P(base + MS60, fs)) &&
                (VBefore.QRS_index == prevQRS.index))
                stimul.hasMalfunctions = true
                return true
            end
        end
    end

    return false
end

function hysteresisCheckV(stimul::Stimul, curQRS::QRS,
    prevQRS::Union{Nothing, QRS}, base::Float64, fs::Float64
)
    if !stimul.malfunction.normal && stimul.stimulVerification == "V"
        if !isnothing(prevQRS)
            dist = abs(stimul.position - prevQRS.position)
            dist = min(curQRS.RR, dist)
            # опять же вопрос об RR 

            if ((MS2P(base + MS60, fs) <= dist <= MS2P(base + MS300, fs)) &&
                !(prevQRS.type[1] in "VF")
            )
                if ((curQRS.position - stimul.position > MS2P(-MS30, fs)) ||
                    curQRS.type[1] == 'C'
                    )
                    stimul.hasMalfunctions = true
                    return true
                end
            end
        end
    end

    return false
end

function noAnswerCheckV(stimul::Stimul, curQRS::QRS,
    prevQRS::Union{Nothing, QRS}, fs::Float64
)
    if ((!stimul.hasMalfunctions || stimul.malfunction.normal) &&
        stimul.stimulVerification == "V" &&
        isMore(stimul, curQRS, MS2P(MS80, fs)) &&
        (isnothing(prevQRS) ||
        stimul.position > ST(prevQRS))
    )
        stimul.type = "VN" 

        return true
    end

    return false
end

function unrelizedCheckV(stimul::Stimul,
    prevQRS::Union{Nothing, QRS}
    )
    # более корректная проверка на нахождение стимула внутри
    # комплекса в контексте моей Structures.jl/findQRS()    
    if ((!stimul.hasMalfunctions || stimul.malfunction.normal) &&
        stimul.stimulVerification == "V" && !isnothing(prevQRS) &&
        prevQRS.position <= stimul.position <= ST(prevQRS)
        )
        stimul.type = "VU"

        return true
    end

    return false
end