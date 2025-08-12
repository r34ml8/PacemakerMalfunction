function analyzeDDD(stimuls::Vector{Stimul}, QRSes::Vector{QRS}, rec::EcgRecord)
    AV50 = MS2P.((rec.intervalAV[1] - MS50, rec.intervalAV[2] + MS50), rec.fs)
    base50 = MS2P.((rec.base - MS50, rec.base + MS50), rec.fs)
    p50 = MS2P.((0, MS50), rec.fs)

    @info typeof.([AV50, base50, p50])
    stimulClassifier(stimuls, QRSes, AV50, base50, p50)

    for (i, stimul) in enumerate(stimuls)
        QRSi = stimul.QRS_index
        curQRS = QRSes[QRSi]
        prevQRS = QRSi > 1 ? QRSes[QRSi - 1] : nothing

        ABefore = findStimulBefore(i, stimuls, 'A')
        VBefore = findStimulBefore(i, stimuls, 'V')
        nextStimul = i < length(stimuls) ? stimuls[i + 1] : nothing

        if stimul.type == "AR"
            _goodAV = goodAV(stimul, curQRS, rec, AV50)

            stimul.malfunction.normal = normalCheckDA(stimul, _goodAV, ABefore, base50, prevQRS, rec)
            stimul.malfunction.oversensingV = oversensingVCheckDA(stimul, _goodAV, ABefore, rec, prevQRS)
            stimul.malfunction.oversensingA = oversensingACheckDA(stimul, _goodAV, ABefore, VBefore, prevQRS, rec)
            stimul.malfunction.undersensingA = undersensingACheckDA(stimul, QRSes, ABefore, base50, curQRS, rec)
            stimul.malfunction.exactlyUndersensingA = exactlyUndersensingACheckDA(stimul, curQRS, rec.fs)
            stimul.malfunction.undersensingV = undersensingVCheckDA(stimul, prevQRS, VBefore, rec)
        elseif stimul.type == "VR"
            stimul.malfunction.normal = normalCheckDV(stimul, curQRS, p50, ABefore, AV50)
            stimul.malfunction.undersensingV = undersensingVCheckDV(stimul, curQRS, ABefore, VBefore, rec.fs, stimuls)
            stimul.malfunction.oversensingAV = oversensingAVCheckDV(stimul, prevQRS, VBefore, stimuls, rec)
            stimul.malfunction.noAnswerV = noAnswerVCheckDV(stimul, curQRS, prevQRS, rec.fs)
            stimul.malfunction.unrelizedV = unrelizedVCheckDV(stimul, curQRS, prevQRS)
        end
    end
end

function normalCheckDA(stimul::Stimul, _goodAV::Bool,
    ABefore::Union{Nothing, Stimul}, base50::Tuple{Int64, Int64},
    prevQRS::Union{Nothing, QRS}, rec::EcgRecord
    )
    if (_goodAV && (isInsideInterval(stimul, ABefore, base50) ||
        isMore(stimul, prevQRS, MS2P(rec.base, rec.fs)))
        )
        return true
    end

    return false
end

function oversensingVCheckDA(stimul::Stimul, _goodAV::Bool,
    ABefore::Union{Nothing, Stimul}, rec::EcgRecord,
    prevQRS::Union{Nothing, QRS}
    )
    if (!stimul.malfunction.normal &&
        (_goodAV || stimul.stimulVerification == "A") &&
        isMore(stimul, ABefore, MS2P(rec.intervalAV[2] + MS100, rec.fs)) &&
        prevQRS.type[1] != 'C'
        )
        stimul.hasMalfunctions = true
        return true
    end

    return false
end

function undersensingVCheckDV(stimul::Stimul, curQRS::QRS,
    ABefore::Union{Nothing, Stimul}, VBefore::Union{Nothing, Stimul},
    fs::Float64, stimuls::Vector{Stimul}
    )
    if (stimul.malfunction.normal && stimul.position > curQRS.position &&
        isInsideInterval(stimul, curQRS, MS2P.((0, MS80), fs)) &&
        (isnothing(ABefore) || ABefore.QRS_index == curQRS.index) &&
        !isnothing(VBefore) && VBefore.malfunction.normal
    )
        beforeVBefore = findStimulBefore(VBefore.index, stimuls, 'V')
        if !isnothing(beforeVBefore)
            dist = VBefore.position - beforeVBefore.position
            if isInsideInterval(stimul, VBefore, MS2P.((dist - MS50, dist + MS50), fs))
                stimul.hasMalfunctions = true
                return true
            end
        end
    end

    return false
end

function oversensingACheckDA(stimul::Stimul, _goodAV::Bool,
    stimuls::Vector{Stimul}, VBefore::Union{Nothing, Stimul},
    prevQRS::Union{Nothing, QRS}, rec::EcgRecord
    )
    if !isnothing(prevQRS) && (_goodAV || stimul.stimulVerification == "A")
        _ABefore = findInQRS(prevQRS, stimuls, 'A')

        if isnothing(_ABefore) && isMore(stimul, prevQRS, MS2P(rec.base + MS100, rec.fs))
            stimul.hasMalfunctions = true
            return true
        end

        if (isMore(stimul, ABefore, MS2P(rec.base + MS200, rec.fs)) &&
            (isnothing(VBefore) || !VBefore.malfunction.oversensingAV)
            )
            stimul.hasMalfunctions = true
            return true
        end
    end

    return false
end

function undersensingACheckDA(stimul::Stimul, QRSes::Vector{QRS},
    ABefore::Union{Nothing, Stimul}, base50::Tuple{Int64, Int64},   
    curQRS::QRS, rec::EcgRecord
    )
    if !stimul.malfunction.normal
        SAWB = findQRSBefore(stimul, QRSes, "SAWB")

        if (isInsideInterval(stimul, SAWB, MS2P.((0, rec.base - MS100), rec.fs)) &&
            curQRS.type[1] in "SAWB" && isInsideInterval(stimul, ABefore, base50)
            )
            stimul.hasMalfunctions = true
            return true
        end
    end

    return false
end

function exactlyUndersensingACheckDA(stimul::Stimul,
    curQRS::QRS, fs::Float64
    )
    if ((stimul.malfunction.normal || stimul.malfunction.undersensingA) &&
        curQRS.type[1] in "SAWB" && isInsideInterval(stimul, curQRS, MS2P.((0, MS80), fs))
        )
        stimul.hasMalfunctions = true
        return true
    end

    return false
end

function undersensingVCheckDA(stimul::Stimul, 
    prevQRS::Union{Nothing, QRS}, VBefore::Union{Nothing, Stimul},
    rec::EcgRecord
    )
    if (stimul.malfunction.normal &&
        isInsideInterval(stimul, prevQRS, MS2P.((0, rec.base - MS200 - rec.intervalAV[2]), rec.fs)) &&
        prevQRS.type[1] != 'C'
        )
        res = isnothing(findInQRS(prevQRS, stimuls, 'V'))
        stimul.hasMalfunctions = res || stimul.hasMalfunctions
        return res
    end

    return false
end

function normalCheckDV(stimul::Stimul, curQRS::QRS,
    p50::Tuple{Int64, Int64}, ABefore::Union{Nothing, Stimul},
    AV50::Tuple{Int64, Int64}
    )
    if (isInsideInterval(stimul, curQRS, p50) ||
        isInsideInterval(stimul, ABefore, AV50)
        )
        return true
    end

    return false
end

function oversensingAVCheckDV(stimul::Stimul, prevQRS::QRS,
    VBefore::Union{Nothing, Stimul}, stimuls::Vector{Stimul},
    rec::EcgRecord
    )
    if stimul.malfunction.normal
        _min = MS2P((rec.base + MS100 + rec.intervalAV[2]), rec.fs)
        if isMore(stimul, prevQRS, _min)
            stimul.hasMalfunctions = true
            return true
        end

        if isnothing(VBefore) || !VBefore.malfunction.oversensingAV
            _ABefore = findInQRS(prevQRS, stimuls, 'A')
            res = isMore(stimul, _ABefore, _min)

            stimul.hasMalfunctions = res || stimul.hasMalfunctions
            return res
        end
    end

    return false
end

function noAnswerVCheckDV(stimul::Stimul, curQRS::QRS,
    prevQRS::Union{Nothing, QRS}, fs::Float64
    )
    if ((stimul.malfunction.normal || !stimul.hasMalfunctions) &&
        isMore(stimul, curQRS, MS2P(MS80, fs)) &&
        (isnothing(prevQRS) || stimul.position > ST(prevQRS))
        )
        stimul.hasMalfunctions = true
        return true
    end

    return false
end

function unrelizedVCheckDV(stimul::Stimul, curQRS::QRS,
    prevQRS::Union{Nothing, QRS}
    )
    if ((stimul.malfunction.normal || !stimul.hasMalfunctions) &&
        (curQRS.position <= stimul.position <= curQRS.position ||
        stimul.position > ST(prevQRS)) 
        )
        stimul.hasMalfunctions = true
        return true
    end

    return false
end