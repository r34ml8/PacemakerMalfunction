
function analyzeVVI(rec::EcgRecord)
    satisfyCheck(rec)

    for stimul in rec.stimuls
        if stimul.satisfy
            stimul.malfunction.normal = normalCheck(stimul, rec)
            stimul.malfunction.undersensing = undersensingCheck(stimul, rec)
            stimul.malfunction.exactlyUndersensing = exactlyUndersensingCheck(stimul, rec)
            stimul.malfunction.oversensing = oversensingCheck(stimul, rec)
            # if normalCheck(stimul, rec)
            #     println("Stimul number $(stimul.index) is normal")
            # else
            #     println("Stimul number $(stimul.index) is anormal:")
            #     if undersensingCheck(stimul, rec)
            #         println("   Undersensing detected")
            #     else
            #         println("   Undersensing not detected")
            #     end
            # end
        end
    end
end

function satisfyCheck(rec::EcgRecord)
    for stimul in rec.stimuls
        if stimul.complex.Z || stimul.type[1] in ('0', 'S')
            stimul.satisfy = false
            continue
        end

        prevComplex = findPrevComplex(stimul, rec)
        if !isnothing(prevComplex) && prevComplex.Z
            stimul.satisfy = false
        end
    end
end 

function normalCheck(stimul::Stimul, rec::EcgRecord)
    if !isInsideInterval(stimul, stimul.complex, [0, 70])
        return false
    end

    interval = [rec.base - 50, rec.base + 50]

    VBefore = findStimulBefore(stimul, rec, 'V')
    if isInsideInterval(stimul, VBefore, interval)
        return true
    end

    prevComplex = findPrevComplex(stimul, rec)
    if isInsideInterval(stimul, prevComplex, interval)
        return true
    end

    VAfter = findStimulAfter(stimul, rec, 'V')
    if isInsideInterval(stimul, VAfter, interval)
        return true
    end

    return false
end

function undersensingCheck(stimul::Stimul, rec::EcgRecord)
    prevComplex = findPrevComplex(stimul, rec)
    return stimul.malfunction.normal ? false : isInsideInterval(stimul, prevComplex, [200, rec.base - 300])
end

function exactlyUndersensingCheck(stimul::Stimul, rec::EcgRecord)
    if stimul.malfunction.undersensing
        interval = [rec.base - 50, rec.base + 50]

        stimulBefore = findStimulBefore(stimul, rec)
        stimulAfter = findStimulAfter(stimul, rec)
        if isInsideInterval(stimul, stimulBefore, interval) || isInsideInterval(stimul, stimulAfter, interval)
            return true
        end

        stimulBeside = findStimulAfter(stimul, rec)
        if isInsideInterval(stimul, stimulBeside, interval)
            return true
        end
    end

    if stimul.malfunction.normal || stimul.malfunction.undersensing
        prevComplex = findPrevComplex(stimul, rec)
        interval .-= stimul.complex.RR 
        if isInsideInterval(stimul, prevComplex, interval)
            return true
        end
    end

    return false
end

function oversensingCheck(stimul::Stimul, rec::EcgRecord)
    if !stimul.malfunction.normal
        prevComplex = findPrevComplex(stimul, rec)
        if isMore(stimul, prevComplex, rec.base + 300)
            VBefore = findStimulBefore(stimul, rec, 'V')
            if isMore(stimul, VBefore, rec.base + 60) && (VBefore.complex.index == prevComplex.index)
                return true
            end
        end
    end

    return false
end

# TODO: функции проверки на гистерезис, без ответа, нереализованный

# function isInsideIntervalPrevComplex(stimul::Stimul, complex::Complex, rec::EcgRecord, interval::Vector{Int})
#     prevComplex = findPrevComplex(stimul, rec)
#     if !isnothing(prevComplex) && (interval[1] <= abs(stimul.position - prevComplex.pos_onset) <= interval[2])
#         return true
#     end

#     return false
# end


function isInsideInterval(stimul::Signal, signal::Union{Signal, Nothing}, interval::Vector{Int})
    if !isnothing(signal) && (interval[1] <= abs(stimul.position - signal.position) <= interval[2])
        return true
    end

    return false
end

function isMore(stimul::Signal, signal::Union{Signal, Nothing}, value::Int)
    if !isnothing(signal) && (abs(stimul.position - signal.position) > value)
        return true
    end

    return false
end

function findStimulBefore(stimul::Stimul, rec::EcgRecord, typeCh::Char = ' ')
    for j in (stimul.index - 1):-1:1
        if rec.stimuls[j].type[1] == typeCh || typeCh == ' '
            return rec.stimuls[j]
        end
    end
    return nothing
end

function findStimulAfter(stimul::Stimul, rec::EcgRecord, typeCh::Char = ' ')
    for j in (stimul.index + 1):length(rec.stimuls)
        if rec.stimuls[j].type[1] == typeCh || typeCh == ' '
            return rec.stimuls[j]
        end
    end
    return nothing
end
