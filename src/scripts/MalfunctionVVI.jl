
function analyzeVVI(rec::EcgRecord)
    satisfyCheck(rec)

    for stimul in rec.stimuls
        if stimul.satisfy
            if normalCheck(stimul, rec)
                println("Stimul number $(stimul.index) is normal")
            else
                println("Stimul number $(stimul.index) is anormal")
            end
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
    if abs(stimul.position - stimul.complex.pos_onset) > 70
        return false
    end

    VBefore = findVBefore(stimul, rec)
    b = rec.base
    if !isnothing(VBefore) && (b - 50 <= abs(stimul.position - VBefore.position) <= b + 50)
        return true
    end

    prevComplex = findPrevComplex(stimul, rec)
    if !isnothing(prevComplex) && (b - 50 <= abs(stimul.position - prevComplex.pos_onset) <= b + 50)
        return true
    end

    VAfter = findVAfter(stimul, rec)
    if !isnothing(VAfter) && (b - 50 <= abs(stimul.position - VAfter.position) <= b + 50)
        return true
    end

    return false
end

function findVBefore(stimul::Stimul, rec::EcgRecord)
    for j in (stimul.index - 1):-1:1
        if rec.stimuls[j].type[1] == 'V'
            return rec.stimuls[j]
        end
    end
    return nothing
end

function findVAfter(stimul::Stimul, rec::EcgRecord)
    for j in (stimul.index + 1):length(rec.stimuls)
        if rec.stimuls[j].type[1] == 'V'
            return rec.stimuls[j]
        end
    end
    return nothing
end
