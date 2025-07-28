function analyzeAAI()
    satisfyCheck()

    for stimul in stimuls
        if stimul.type != "U"
            stimul.malfunction.normal = normalCheck(stimul)

            stimul.malfunction.undersensing = undersensingCheck(stimul)

            stimul.malfunction.exactlyUndersensing = exactlyUndersensingCheck(stimul)
        end
    end
end

function normalCheck(stimul::Stimul)
    interval = [base - MS50, base + MS50]

    ABefore = findStimulBefore(stimul, 'A')
    if isInsideInterval(stimul, ABefore, interval)
        return true
    end

    if isMore(stimul, prevComplex, base - MS200)
        return true
    end

    AAfter = findStimulAfter(stimul, 'A')
    if isInsideInterval(stimul, AAfter, interval)
        return true
    end

    return false
end

function undersensingCheck(stimul::Stimul)
    if stimul.malfunction.normal
        return false
    end

    SAWB = findComplexBefore(stimul, "SAWB")
    return isInsideInterval(stimul, SAWB, [0, base - MS300])
end

function exactlyUndersensingCheck(stimul::Stimul)
    if !stimul.malfunction.undersensing
        return false
    end

    stimulBefore = findStimulBefore(stimul)
    return isInsideInterval(stimul, stimulBefore, [base - MS50, base + MS50])
end

function oversensingCheck()
    if stimul.malfunction.oversensing
        return false
    end

    prevComplex = findPrevComplex(stimul)
    if !isnothing(prevComplex) && prevComplex.type[1] in "SAWB"
        if isMore(stimul, prevComplex, base - MS300)
            return true
        end
        # TODO: доделать + частота дискретизации + переделать весь код
    end
end