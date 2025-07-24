
function analyzeVVI()
    satisfyCheck()

    for stimul in stimuls
        if stimul.satisfy
            print(stimul.index, " ")

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
                println("oversensing ")
            else
                println()
                # println("no oversensing ")
            end
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

    prevComplex = findPrevComplex(stimul)
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
    prevComplex = findPrevComplex(stimul)
    return stimul.malfunction.normal ? false : isInsideInterval(stimul, prevComplex, [200, base - 300])
end

function exactlyUndersensingCheck(stimul::Stimul)
    interval = [base - 50, base + 50]

    if stimul.malfunction.undersensing
        stimulBefore = findStimulBefore(stimul)
        stimulAfter = findStimulAfter(stimul)
        if isInsideInterval(stimul, stimulBefore, interval) || isInsideInterval(stimul, stimulAfter, interval)
            return true
        end

        stimulBeside = findStimulAfter(stimul)
        if isInsideInterval(stimul, stimulBeside, interval)
            return true
        end
    end

    if stimul.malfunction.normal || stimul.malfunction.undersensing
        prevComplex = findPrevComplex(stimul)
        interval .-= stimul.complex.RR 
        if isInsideInterval(stimul, prevComplex, interval)
            return true
        end
    end

    return false
end

function oversensingCheck(stimul::Stimul)
    if !stimul.malfunction.normal
        prevComplex = findPrevComplex(stimul)
        if isMore(stimul, prevComplex, base + 300)
            VBefore = findStimulBefore(stimul, 'V')
            if isMore(stimul, VBefore, base + 60) && (VBefore.complex.index == prevComplex.index)
                return true
            end
        end
    end

    return false
end

# function hysteresisCheck(stimul::Stimul)
#     if stimul.malfunction.normal
#         prevComplex = findPrevComplex(stimul)
#         if !isnothing(prevComplex)
#             dist = abs(stimul.position - prevComplex.position)
#             dist = min(stimul.complex.RR, dist)
#             if (
#                 (base + 60 <= dist <= base + 300) &&
#                 (isMore(stimul, stimul.complex, 30) ||
#                 _)
#             )
#             end
#         end
#     end

#     return false
# end

# TODO: функции проверки на гистерезис, без ответа, нереализованный

# function isInsideIntervalPrevComplex(stimul::Stimul, complex::Complex, rec::EcgRecord, interval::Vector{Int})
#     prevComplex = findPrevComplex(stimul, rec)
#     if !isnothing(prevComplex) && (interval[1] <= abs(stimul.position - prevComplex.pos_onset) <= interval[2])
#         return true
#     end

#     return false
# end


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
        if stimuls[j].type[1] == typeCh || typeCh == ' '
            return stimuls[j]
        end
    end
    return nothing
end

function findStimulAfter(stimul::Stimul, typeCh::Char = ' ')
    for j in (stimul.index + 1):length(stimuls)
        if stimuls[j].type[1] == typeCh || typeCh == ' '
            return stimuls[j]
        end
    end
    return nothing
end
