module PacemakerMalfunction

import FileUtils.StdEcgDbAPI as API

include("scripts\\Reading.jl")
export get_data_from, hdr_reading


include("scripts\\Structures.jl")
export Signal, Complex, Stimul,
    Malfunctions, MalfunctionsVVI,
    MalfunctionsAAI, MalfunctionsDDD,
    baseParams, findPrevComplex

include("scripts\\StimulClassifier.jl")
export classify_spikes

include("scripts\\SecondaryFunctions.jl")
export ST, isInsideInterval, isMore,
    findStimulBefore, findStimulAfter,
    VCheck, satisfyCheck, findComplexBefore

include("scripts\\MalfunctionVVI.jl")
export analyzeVVI, mediana

end
