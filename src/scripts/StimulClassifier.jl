function stimul_type(
    stimpos::Vector{Int64},
    QRS_onset::Vector{Int64},
    refzone::Int64,
    errb::Int64
    )

    stimtype = map(stimpos) do pos
        for i in 1:lastindex(QRS_onset)-1
            if QRS_onset[i]-errb < pos <= QRS_onset[i]+errb
                return "V"
            elseif QRS_onset[i]+errb < pos <= QRS_onset[i]+refzone-errb
                return "U"
            elseif QRS_onset[i]+refzone-errb < pos <= QRS_onset[i+1]-errb
                return "A"
            else
                # continue
            end
        end
        return "U"
    end

    return stimtype
end

function stimulClassifier(stimuls::Vector{Stimul},
    QRSes::Vector{QRS}, rec::EcgRecord
    )
    AV50 = MS2P.((rec.intervalAV[1] - MS50, rec.intervalAV[2] + MS50), rec.fs)
    base50 = MS2P.((rec.base - MS50, rec.base + MS50), rec.fs)

    prevA = false
    posA = 0
    QRSiA = 0
    # @info rec.intervalAV
    for (i, stimul) in enumerate(stimuls)
        QRSi = stimul.QRS_index

        curQRS = QRSes[QRSi]
        prevQRS = QRSi > 1 ? QRSes[QRSi - 1] : nothing

        if satisfyCheck(curQRS, prevQRS)
            ABefore = findStimulBefore(i, stimuls, 'A')
            VBefore = findStimulBefore(i, stimuls, 'V')
            nextStimul = i < length(stimuls) ? stimuls[i + 1] : nothing

            stimulVerification = stimul.type
            
            maybeV = stimulVerification == "V" && (inQRS(QRSi, VBefore) || stimul.type == "U") ? true : false
            maybeA = stimulVerification == "A" ? true : false

            likelyV = stimul.type == "V" || maybeV ? true : false
            likelyA = stimul.type == "A" || maybeA ? true : false

            exactV = false
            if likelyV
                if (curQRS.type[1] == 'C' ||
                    isInsideInterval(stimul, curQRS, MS2P.((0, MS50), rec.fs)) ||
                    isInsideInterval(stimul, VBefore, base50)
                )
                    exactV = true
                end
            end
            @info exactV

            if inQRS(QRSi, ABefore) && isInsideInterval(stimul, ABefore, AV50)
                exactV = true
            end
            @info exactV

            exactA = false
            if !exactV
                if likelyA
                    if (curQRS.type[1] in "SAWB" ||
                        isInsideInterval(stimul, nextStimul, base50) ||
                        inQRS(QRSi, nextStimul) && nextStimul.type == "V" &&
                        isInsideInterval(stimul, nextStimul, AV50) ||
                        curQRS.type[1] != 'C' && isInsideInterval(stimul, ABefore, base50)
                    )
                        exactA = true
                    end
                end

                if (curQRS.type[1] == 'C' &&
                    !isnothing(nextStimul) && nextStimul.type == "V" &&
                    isInsideInterval(stimul, ABefore, base50)
                )
                    exactA = true
                end
            end
            @info stimul.type, stimul.position

            if exactV
                stimul.type = "VR"
            elseif exactA
                stimul.type = "AR"
            else
                stimul.type = likelyV ? "VR" : "AR"
            end
        else
            stimul.type = "U"
        end

        if stimul.type == "AR"
            prevA = true
            posA = stimul.position
            QRSiA = QRSi
        elseif prevA && stimul.type == "VR" && QRSi == QRSiA
            QRSes[QRSi].AV = stimul.position - posA
            prevA = false
        end
    end
end