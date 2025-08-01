function pacemaker_analyze(hdr_path::String, mkp_path::String)
    mkpBase = get_data_from(mkp_path, "mkp")
    rec = get_data_from(hdr_path, "hdr")

    QRSes, stimuls = mkpSignals(mkpBase, rec)

    if rec.mode[1:3] == "VVI"
        analyzeVVI(stimuls, QRSes, rec.base, rec.fs)
    elseif rec.mode[1:3] == "AAI"
        analyzeAAI(stimul, QRSes, rec.base, rec.fs)
    end

    dfMalf = DataFrame(getproperty.(stimuls, :malfunction))

    return dfMalf
end
