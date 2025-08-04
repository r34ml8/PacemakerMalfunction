module PacemakerMalfunction

import FileUtils.StdEcgDbAPI as API

include("scripts\\Structures.jl")
export Signal, QRS, Stimul,
    Malfunctions, MalfunctionsVVI,
    MalfunctionsAAI, MalfunctionsDDD,
    baseParams, findPrevQRS

include("scripts\\Reading.jl")
export get_data_from

include("scripts\\StimulClassifier.jl")
export classify_spikes

include("scripts\\SecondaryFunctions.jl")
export ST, isInsideInterval, isMore,
    findStimulBefore, findStimulAfter,
    VCheck, satisfyCheck, findQRSBefore,
    mediana

include("scripts\\MalfunctionVVI.jl")
export analyzeVVI

include("scripts\\MalfunctionAAI.jl")
export analyzeAAI

include("scripts\\StimulClassifier.jl")
export stimulClassifier

include("scripts\\Analyze.jl")
export pacemaker_analyze

end
