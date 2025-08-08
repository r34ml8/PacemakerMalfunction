function pacemaker_analyze(hdr_path::String, mkp_path::String)
    mkpBase = get_data_from(mkp_path, "mkp")
    rec = get_data_from(hdr_path, "hdr")

    QRSes, stimuls = mkpSignals(mkpBase, rec)
    if rec.mode[1:3] == "DDD"
        analyzeDDD(stimuls, QRSes, rec)
        return getproperty.(stimuls, :type), DDDtoMalfVec(stimuls, QRSes)
    elseif rec.mode[1:3] == "VVI"
        analyzeVVI(stimuls, QRSes, rec.base, rec.fs)
        for stimul in stimuls
            if stimul.type == "V"
                stimul.type = "VR"
            end
        end
    elseif rec.mode[1:3] == "AAI"
        analyzeAAI(stimuls, QRSes, rec.base, rec.fs)
        for stimul in stimuls
            if stimul.type == "A"
                stimul.type = "AR"
            end
        end
    end

    return getproperty.(stimuls, :type), VAtoMalfVec(stimuls, QRSes, rec.mode)
end

struct StimIssue
    issue::String
    channel::String
    mask::BitVector

    function StimIssue(issue::String, channel::String, malf::BitVector, stimuls::Vector{Stimul}, QRSes::Vector{QRS})
        mask = BitVector(undef, length(QRSes))
        for i in eachindex(malf)
            if malf[i]
                QRSi = stimuls[i].QRS_index

                mask[QRSi] = 1
                if QRSi > 1
                    mask[QRSi - 1] = 1
                end
            end
        end

        return new(issue, channel, mask)
    end
end

function VAtoMalfVec(stimuls::Vector{Stimul}, QRSes::Vector{QRS}, mode::String)
    stimissues = StimIssue[]
    malfs = getproperty.(stimuls, :malfunction)
    channel = mode[1:3] == "VVI" ? "V" : "A"

    hypo = getproperty.(malfs, :undersensing)
    exacthypo = getproperty.(malfs, :exactlyUndersensing)
    for (h, eh) in zip(hypo, exacthypo)
        h = h || eh
    end
    push!(stimissues, StimIssue("hyposensing", channel, hypo, stimuls, QRSes))

    if mode[1:3] == "VVI"
        hyster = getproperty.(malfs, :hysteresis)
        push!(stimissues, StimIssue("hysteresis", channel, hyster, stimuls, QRSes))
    end

    hyper = getproperty.(malfs, :oversensing)
    push!(stimissues, StimIssue("hypersensing", channel, hyper, stimuls, QRSes))

    nocapt = getproperty.(malfs, :noAnswer)
    push!(stimissues, StimIssue("no_capture", channel, nocapt, stimuls, QRSes))

    return stimissues
end

function DDDtoMalfVec(stimuls::Vector{Stimul}, QRSes::Vector{QRS})
    stimissues = StimIssue[]
    malfs = getproperty.(stimuls, :malfunction)

    hyperV = getproperty.(malfs, :oversensingV)
    push!(stimissues, StimIssue("hypersensing", "V", hyperV, stimuls, QRSes))

    hypoV = getproperty.(malfs, :undersensingV)
    push!(stimissues, StimIssue("hyposensing", "V", hypoV, stimuls, QRSes))

    hyperA = getproperty.(malfs, :oversensingA)
    push!(stimissues, StimIssue("hypersensing", "A", hyperA, stimuls, QRSes))

    hypoA = getproperty.(malfs, :undersensingA)
    exacthypoA = getproperty.(malfs, :exactlyUndersensingA)
    for (h, eh) in zip(hypoA, exacthypoA)
        h = h || eh
    end
    push!(stimissues, StimIssue("hyposensing", "A", hypoA, stimuls, QRSes))

    hyperAV = getproperty.(malfs, :oversensingAV)
    push!(stimissues, StimIssue("hypersensing", "V/A", hyperAV, stimuls, QRSes))

    nocaptV = getproperty.(malfs, :noAnswerV)
    push!(stimissues, StimIssue("no_capture", "V", nocaptV, stimuls, QRSes))

    return stimissues
end