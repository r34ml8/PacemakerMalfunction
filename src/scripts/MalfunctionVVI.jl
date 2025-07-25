
function analyzeVVI()
    satisfyCheck()

    for stimul in stimuls
        if stimul.satisfy
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

function satisfyCheck()
    for stimul in stimuls
        if stimul.complex.type == "Z" || stimul.type[1] in ('0', 'S')
            stimul.satisfy = false
            continue
        end

        prevComplex = findPrevComplex(stimul)
        if !isnothing(prevComplex) && prevComplex.type == "Z"
            stimul.satisfy = false
        end
    end
end 

function normalCheck(stimul::Stimul)
    if !isInsideInterval(stimul, stimul.complex, [0, 70])
        return false
    end

    interval = [base - 50, base + 50]

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
    res = stimul.malfunction.normal ? false : isInsideInterval(stimul, prevComplex, [200, base - 300])
    if res
        stimul.type = "V"
    end
    return res
end

function exactlyUndersensingCheck(stimul::Stimul)
    interval = [base - 50, base + 50]

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
        if isMore(stimul, prevComplex, base + 300)
            VBefore = findStimulBefore(stimul, 'V')
            if isMore(stimul, VBefore, base + 60) && (VBefore.complex.index == prevComplex.index)
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
                (base + 60 <= dist <= base + 300) &&
                (!isMore(stimul, stimul.complex, 30) &&
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
        isMore(stimul, stimul.complex, 80)
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
            !isMore(stimul, stimul.complex, 80) &&
            stimul.complex.position + 15 < stimul.position
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



# TODO: функции проверки на гистерезис, без ответа, нереализованный

# function isInsideIntervalPrevComplex(stimul::Stimul, complex::Complex, rec::EcgRecord, interval::Vector{Int})
#     prevComplex = findPrevComplex(stimul, rec)
#     if !isnothing(prevComplex) && (interval[1] <= abs(stimul.position - prevComplex.pos_onset) <= interval[2])
#         return true
#     end

#     return false
# end

function ST(complex::Complex)
    excess = complex.pos_end - complex.pos_end
    excess = excess > 120 ? excess - 120 : 0
    return round(complex.pos_end + 0.42 * sqrt(complex.RR) - excess)
end

function isInsideInterval(stimul::Signal, signal::Union{Signal, Nothing}, interval::Vector{<:Real})
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

function findStimulBefore(stimul::Stimul, typeCh::Char = ' ')
    for j in (stimul.index - 1):-1:1
        if (
            (typeCh == ' ') ||
            (typeCh == 'V') && VCheck(stimul)
        )
            return stimuls[j]
        end
    end

    return nothing
end

function findStimulAfter(stimul::Stimul, typeCh::Char = ' ')
    for j in (stimul.index + 1):length(stimuls)
        if (
            (typeCh == ' ') ||
            (typeCh == 'V') && VCheck(stimul)
        )
            return stimuls[j]
        end
    end
    return nothing
end

function VCheck(stimul::Stimul)
    return stimul.malfunction.normal || stimul.type in ("V", "VR") ? true : false
end
