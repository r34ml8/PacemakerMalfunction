module PacemakerMalfunction

import FileUtils.StdEcgDbAPI as API

include("scripts\\Reading.jl")
export get_data_from, hdr_reading

include("scripts\\EcgChar.jl")
export Signal, Complex, Stimul,
    Malfunctions, MalfunctionsVVI,
    MalfunctionsAAI, MalfunctionsDDD,
    baseParams, findPrevComplex

include("scripts\\StimulClassifier.jl")
export classify_spikes

mode = 0
base = 0
complexes = Complex[]
stimuls = Stimul[]

include("scripts\\MalfunctionVVI.jl")
export analyzeVVI

end
