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

        elseif stimul.type == "VR"
            stimul.malfunction.normal = normalCheckDV(stimul, curQRS, p50, ABefore, AV50)

            stimul.malfunction.undersensingV = undersensingVCheckDV(stimul, curQRS, ABefore, VBefore, rec.fs, stimuls)
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
                return true
            end
        end
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