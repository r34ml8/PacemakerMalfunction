
function analyzeVVI(stimuls::Vector{Stimul},
    QRSes::Vector{QRS}, base::Float64, fs::Float64
)
    interval50 = MS2P.((base - MS50, base + MS50), fs)
    for stimul in stimuls
        curQRS = QRSes[stimul.QRS_index]
        prevQRS = stimul.QRS_index > 1 ? QRSes[stimul.QRS_index - 1] : nothing
        
        if satisfyCheck(curQRS, prevQRS)
            stimul.type = "VR"

            print(stimul.index, " ")

            stimul.malfunction.normal = normalCheck(stimul, stimuls, curQRS, prevQRS, interval50, fs)
            if stimul.malfunction.normal
                # print("normal ")
            else
                print("anormal ")
            end

            stimul.malfunction.undersensing = undersensingCheck(stimul, prevQRS, base, fs)
            if stimul.malfunction.undersensing
                print("undersensing ")
            else
                # print("no undersensing ")
            end

            stimul.malfunction.exactlyUndersensing = exactlyUndersensingCheck(stimul, stimuls, curQRS, prevQRS, interval50)
            if stimul.malfunction.exactlyUndersensing
                print("exactly undersensing ")
            else
                # print("exactly no undersensing ")
            end

            stimul.malfunction.oversensing = oversensingCheck(stimul, stimuls, prevQRS, base, fs)
            if stimul.malfunction.oversensing
                print("oversensing ")
            else
                # println("no oversensing ")
            end

            stimul.malfunction.hysteresis = hysteresisCheck(stimul, curQRS, prevQRS, base, fs)
            if stimul.malfunction.hysteresis
                print("hysteresis ")
            else
                # print("no hysteresis ")
            end

            stimul.malfunction.noAnswer = noAnswerCheck(stimul, curQRS, prevQRS, fs)
            if stimul.malfunction.noAnswer
                print("has no answer ")
            else
                # print("has answer ")
            end

            stimul.malfunction.unrelized = unrelizedCheck(stimul, curQRS, prevQRS, fs)
            if stimul.malfunction.unrelized
                print("unrelized ")
            else
                # print("relized ")
            end

            println()
        else
            stimul.type = "U"
        end
    end
end

function normalCheck(stimul::Stimul, stimuls::Vector{Stimul},
    curQRS::QRS, prevQRS::QRS, interval::Tuple{Int64, Int64}, fs::Float64
)
    if !isInsideInterval(stimul, curQRS, MS2P.((0, MS70), fs))
        return false
    end

    VBefore = findStimulBefore(stimul.index, stimuls, 'V')
    if isInsideInterval(stimul, VBefore, interval)
        return true
    end

    if isInsideInterval(stimul, prevQRS, interval)
        return true
    end

    VAfter = findStimulAfter(stimul.index, stimuls, 'V')
    if isInsideInterval(stimul, VAfter, interval)
        return true
    end

    return false
end

function undersensingCheck(stimul::Stimul,
    prevQRS::Union{Nothing, QRS}, base::Float64, fs::Float64
)
    if !stimul.malfunction.normal
        res = isInsideInterval(stimul, prevQRS, MS2P.((MS200, base - MS300), fs))
        stimul.type = res ? "V" : "VR"
        return res
    end

    return false
end

function exactlyUndersensingCheck(stimul::Stimul,
    stimuls::Vector{Stimul}, curQRS::QRS, prevQRS::Union{Nothing, QRS},
    interval::Tuple{Int64, Int64}
)
    if stimul.malfunction.undersensing
        stimulBefore = findStimulBefore(stimul.index, stimuls)
        stimulAfter = findStimulAfter(stimul.index, stimuls)

        if (isInsideInterval(stimul, stimulBefore, interval) ||
            isInsideInterval(stimul, stimulAfter, interval)
        )
            stimul.type = "V"
            return true
        end
    end

    if stimul.malfunction.normal || stimul.malfunction.undersensing
        interval = interval .- curQRS.RR 
        if isInsideInterval(stimul, prevQRS, interval)
            stimul.type = "V"
            return true
        end
    end

    return false
end

function oversensingCheck(stimul::Stimul, stimuls::Vector{Stimul},
    prevQRS::Union{Nothing, QRS}, base::Float64, fs::Float64
)
    if !stimul.malfunction.normal
        if isMore(stimul, prevQRS, MS2P(base + MS300, fs))
            VBefore = findStimulBefore(stimul, stimuls, 'V')

            if (isMore(stimul, VBefore, MS2P(base + MS60, fs)) &&
                (VBefore.QRS_index == prevQRS.index))
                stimul.type = "V"

                return true
            end
        end
    end

    return false
end

function hysteresisCheck(stimul::Stimul, curQRS::QRS,
    prevQRS::Union{Nothing, QRS}, base::Float64, fs::Float64
)
    if stimul.malfunction.normal
        if !isnothing(prevQRS)
            dist = abs(stimul.position - prevQRS.position)
            dist = min(curQRS.RR, dist)

            if (
                (MS2P(base + MS60, fs) <= dist <= MS2P(base + MS300, fs)) &&
                (!isMore(stimul, curQRS, MS2P(MS30, fs)) &&
                stimul.position > curQRS.position ||
                curQRS.type[1] == 'C') &&
                !(prevQRS.type[1] in ('V', 'F'))
            )
                stimul.type = "V"
                return true
            end
        end
    end

    return false
end

function noAnswerCheck(stimul::Stimul, curQRS::QRS,
    prevQRS::Union{Nothing, QRS}, fs::Float64
)
    if (
        (stimul.type == "VR" || stimul.malfunction.normal) &&
        isMore(stimul, curQRS, MS2P(MS80, fs)) &&
        (isnothing(prevQRS) ||
        stimul.position > ST(prevQRS))
    )
        stimul.type = "VN" 
        return true
    end

    return false
end

function unrelizedCheck(stimul::Stimul, curQRS::QRS,
    prevQRS::Union{Nothing, QRS}, fs::Float64
)
    if stimul.type == "VR" || stimul.malfunction.normal
        if (!isMore(stimul, curQRS, MS2P(MS80, fs)) &&
            curQRS.position + MS2P(MS15, fs) < stimul.position
        )
            stimul.type = "VU"
            return true
        else
            if (!isnothing(prevQRS) &&
                stimul.position < ST(prevQRS)
            )
                stimul.type = "VU"
                return true
            end
        end
    end

    return false
end