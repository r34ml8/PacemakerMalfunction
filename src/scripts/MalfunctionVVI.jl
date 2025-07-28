
function analyzeVVI()
    satisfyCheck()

    for stimul in stimuls
        if stimul.type != "U"
            print(stimul.index, " ")

            stimul.type = "VR"
            global prevComplex = findPrevComplex(stimul)

            stimul.malfunction.normal = normalCheck(stimul)
            if stimul.malfunction.normal
                # print("normal ")
            else
                print("anormal ")
            end

            stimul.malfunction.undersensing = undersensingCheck(stimul)
            if stimul.malfunction.undersensing
                print("undersensing ")
            else
                # print("no undersensing ")
            end

            stimul.malfunction.exactlyUndersensing = exactlyUndersensingCheck(stimul)
            if stimul.malfunction.exactlyUndersensing
                print("exactly undersensing ")
            else
                # print("exactly no undersensing ")
            end

            stimul.malfunction.oversensing = oversensingCheck(stimul)
            if stimul.malfunction.oversensing
                print("oversensing ")
            else
                # println("no oversensing ")
            end

            stimul.malfunction.hysteresis = hysteresisCheck(stimul)
            if stimul.malfunction.hysteresis
                print("hysteresis ")
            else
                # print("no hysteresis ")
            end

            stimul.malfunction.noAnswer = noAnswerCheck(stimul)
            if stimul.malfunction.noAnswer
                print("has no answer ")
            else
                # print("has answer ")
            end

            stimul.malfunction.unrelized = unrelizedCheck(stimul)
            if stimul.malfunction.unrelized
                print("unrelized ")
            else
                # print("relized ")
            end

            println()
        end
    end
end

function normalCheck(stimul::Stimul)
    if !isInsideInterval(stimul, stimul.complex, [0, MS70])
        return false
    end

    interval = [base - MS50, base + MS50]

    VBefore = findStimulBefore(stimul, 'V')
    if isInsideInterval(stimul, VBefore, interval)
        return true
    end

    if isInsideInterval(stimul, prevComplex, interval)
        return true
    end

    VAfter = findStimulAfter(stimul, 'V')
    if isInsideInterval(stimul, VAfter, interval)
        return true
    end

    return false
end

function undersensingCheck(stimul::Stimul)
    res = stimul.malfunction.normal ? false : isInsideInterval(stimul, prevComplex, [MS200, base - MS300])
    if res
        stimul.type = "V"
    end
    return res
end

function exactlyUndersensingCheck(stimul::Stimul)
    interval = [base - MS50, base + MS50]

    if stimul.malfunction.undersensing
        stimulBefore = findStimulBefore(stimul)
        stimulAfter = findStimulAfter(stimul)
        if isInsideInterval(stimul, stimulBefore, interval) || isInsideInterval(stimul, stimulAfter, interval)
            stimul.type = "V"
            return true
        end

        stimulBeside = findStimulAfter(stimul)
        if isInsideInterval(stimul, stimulBeside, interval)
            stimul.type = "V"
            return true
        end
    end

    if stimul.malfunction.normal || stimul.malfunction.undersensing
        interval .-= stimul.complex.RR 
        if isInsideInterval(stimul, prevComplex, interval)
            stimul.type = "V"
            return true
        end
    end

    return false
end

function oversensingCheck(stimul::Stimul)
    if !stimul.malfunction.normal
        if isMore(stimul, prevComplex, base + MS300)
            VBefore = findStimulBefore(stimul, 'V')
            if isMore(stimul, VBefore, base + MS60) && (VBefore.complex.index == prevComplex.index)
                stimul.type = "V"
                return true
            end
        end
    end

    return false
end

function hysteresisCheck(stimul::Stimul)
    if stimul.malfunction.normal
        if !isnothing(prevComplex)
            dist = abs(stimul.position - prevComplex.position)
            dist = min(stimul.complex.RR, dist)

            if (
                (base + MS60 <= dist <= base + MS300) &&
                (!isMore(stimul, stimul.complex, MS30) &&
                stimul.position > stimul.complex.position ||
                stimul.complex.type[1] == 'C') &&
                !(prevComplex.type[1] in ('V', 'F'))
            )
                stimul.type = "V"
                return true
            end
        end
    end

    return false
end

function noAnswerCheck(stimul::Stimul)
    if (
        (stimul.type == "VR" || stimul.malfunction.normal) &&
        isMore(stimul, stimul.complex, MS80)
    )
        if (
            isnothing(prevComplex) ||
            stimul.position > ST(prevComplex)
        )
            stimul.type = "VN"
            return true
        end
    end

    return false
end

function unrelizedCheck(stimul::Stimul)
    if stimul.type == "VR" || stimul.malfunction.normal
        if (
            !isMore(stimul, stimul.complex, MS80) &&
            stimul.complex.position + MS15 < stimul.position
        )
            stimul.type = "VU"
            return true
        else
            if (
                !isnothing(prevComplex) &&
                stimul.position < ST(prevComplex)
            )
                stimul.type = "VU"
                return true
            end
        end
    end

    return false
end