function satisfyCheck()
    for stimul in stimuls
        if stimul.complex.type == "Z"
            stimul.type = "U"
            continue
        end

        prevComplex = findPrevComplex(stimul)
        if !isnothing(prevComplex) && prevComplex.type == "Z"
            stimul.type = "U"
        end
    end
end 

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
            typeCh == ' ' ||
            typeCh == 'V' && VCheck(stimuls[j]) ||
            typeCh == 'A' && stimuls[j].type[1] == 'A'
        )
            return stimuls[j]
        end
    end

    return nothing
end

function findStimulAfter(stimul::Stimul, typeCh::Char = ' ')
    for j in (stimul.index + 1):length(stimuls)
        if (
            typeCh == ' ' ||
            typeCh == 'V' && VCheck(stimuls[j]) ||
            typeCh == 'A' && stimuls[j].type[1] == 'A'
        )
            return stimuls[j]
        end
    end
    return nothing
end

function VCheck(stimul::Stimul)
    return stimul.malfunction.normal || stimul.type in ("V", "VR") ? true : false
end

function mediana(vec)
    med = vec[1]

    dict = Dict(i => 0 for i in unique(vec))
    for elem in vec
        dict[elem] += 1
        med = dict[elem] == maximum(values(dict)) ? elem : med
    end
    return med
end

function findComplexBefore(stimul::Stimul, typeStr::String)
    for j in (stimul.complex.index - 1):-1:1
        if complexes[j].type[1] in typeStr
            return complexes[j]
        end
    end

    return nothing
end