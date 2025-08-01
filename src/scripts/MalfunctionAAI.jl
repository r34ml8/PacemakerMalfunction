function analyzeAAI(stimuls::Vector{Stimul},
    QRSes::Vector{QRS}, base::Float64, fs::Float64
)
    for (i, stimul) in enumerate(stimuls)
        curQRS = QRSes[stimul.QRS_index]
        prevQRS = stimul.QRS_index > 1 ? QRSes[stimul.QRS_index - 1] : nothing

        if satisfyCheck(curQRS, prevQRS)
            stimul.type = "AR"

            print("$(stimul.index) $(stimul.QRS_index) ")

            interval50 = MS2P.((base - MS50, base + MS50), fs)

            if i > 1
                stimuls[i - 1].malfunction.noAnswer = noAnswerCheckA(stimul, stimuls, curQRS)
                if stimuls[i - 1].malfunction.noAnswer
                    print("prev has no answer ")
                else
                    # print("has answer ")
                end
            end

            stimul.malfunction.normal = normalCheckA(stimul, stimuls, curQRS, prevQRS, interval50, base, fs)
            if stimul.malfunction.normal
                # print("normal ")
            else
                print("anormal ")
            end

            stimul.malfunction.undersensing = undersensingCheckA(stimul, QRSes, base, fs)
            if stimul.malfunction.undersensing
                print("undersensing ")
            else
                # print("no undersensing ")
            end

            stimul.malfunction.exactlyUndersensing = exactlyUndersensingCheckA(stimul, stimuls, interval50)
            if stimul.malfunction.exactlyUndersensing
                print("exactly undersensing ")
            else
                # print("exactly no undersensing ")
            end

            stimul.malfunction.oversensing = oversensingCheckA(stimul, stimuls, prevQRS, base, fs)
            if stimul.malfunction.oversensing
                print("oversensing ")
            else
                # println("no oversensing ")
            end

            stimul.malfunction.unrelized = unrelizedCheckA(stimul, curQRS, prevQRS)
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

function normalCheckA(stimul::Stimul, stimuls::Vector{Stimul},
    curQRS::QRS, prevQRS::Union{Nothing, QRS},
    interval::Tuple{Int64, Int64}, base::Float64, fs::Float64
)
    ABefore = findStimulBefore(stimul.index, stimuls, 'A')
    if (!isnothing(ABefore) && 
        ABefore.QRS_index == curQRS.index &&
        ABefore.malfunction.normal
    )
        println("hereherehere")
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

function undersensingCheckA(stimul::Stimul, QRSes::Vector{QRS},
    base::Float64, fs::Float64
)
    # if stimul.malfunction.normal
    #     return false
    # end

    SAWB = findQRSBefore(stimul, QRSes, "SAWB")
    res = isInsideInterval(stimul, SAWB, MS2P.((0, base - MS300), fs))
    stimul.type = res ? "A" : "AR"

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
    stimul.type = res ? "A" : "AR"

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
            stimul.type = "A"
            return true
        end

        ABefore = findStimulBefore(stimul.index, stimuls, 'A')
        if (!isnothing(ABefore) &&
            ABefore.QRS_index == prevQRS.index &&
            isMore(stimul, ABefore, MS2P(base + MS60, fs))
        )
            stimul.type = "A"
            return true
        end
    end

    return false
end

function noAnswerCheckA(stimul::Stimul, stimuls::Vector{Stimul},
    curQRS::QRS)
    if (ACheck(stimul))
        ABefore = findStimulBefore(stimul.index, stimuls, 'A')
        if (!isnothing(ABefore) &&
            ABefore.QRS_index == curQRS.index)
            stimuls[ABefore.index].type = "AN"
            return true
        end
    end

    return false
end

function unrelizedCheckA(stimul::Stimul, curQRS::QRS,
    prevQRS::Union{Nothing, QRS}
)
    mid = prevQRS.pos_end
    mid += (curQRS.position - prevQRS.pos_end) / 4
    if prevQRS.position <= stimul.position <= mid
        stimul.type = "AU"
        return true
    end

    return false
end