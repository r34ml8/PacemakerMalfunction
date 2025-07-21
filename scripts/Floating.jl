module Floating

import PM

# @kwdef mutable struct BeforeComplexChar
#     beforeVStimul::Union{Stimul, Nothing} = Nothing
#     beforeAStimul::Union{Stimul, Nothing} = Nothing
#     beforeSAWBComplex::Union{Int, Nothing} = Nothing
#     beforeComplex::Union{Int, Nothing} = Nothing
#     beforeComplexStart::Union{Int, Nothing} = Nothing
#     beforeComplexWidth::Union{Int, Nothing} = Nothing
#     beforeComplexRR::Union{Int, Nothing} = Nothing
#     beforeStimulComplex::Union{Int, Nothing} = Nothing
# end

@kwdef mutable struct ComplexChar
    # Base::Int #???
    B::Int #???
    # MaxBase::Int #???
    # AV::Int #???
    # IntervalAV::Int #???
    # ComplexAV::Int
    SpikeCount::Int #???
    ZeroSpikeCount::Int #???
    # NextVIndex::Union{Int, Nothing} = Nothing
    RR::Int
    # NextComplexCC::Union{Int, Nothing} = Nothing
    CurComplexCCPlus::Union{Int, Nothing} = nothing
    # Complex::Int
    CurrentZ::Bool = False
    BeforeZ::Bool = False
    # ST::Int

    beforeVStimul::Union{Stimul, Nothing} = nothing
    # beforeAStimul::Union{Stimul, Nothing} = Nothing
    # beforeSAWBComplex::Union{Int, Nothing} = Nothing
    beforeComplex::Union{Int, Nothing} = nothing
    # beforeComplexStart::Union{Int, Nothing} = Nothing
    # beforeComplexWidth::Union{Int, Nothing} = Nothing
    beforeComplexRR::Union{Int, Nothing} = nothing
    beforeStimulComplex::Union{Int, Nothing} = nothing
end

@kwdef mutable struct Stimul
    StimulPosition::Int
    StimulComplex::Int
    StimulBeforeComplex::Union{Int, Nothing} = Nothing
    StimulType::String
    StimulVerification::String #???
end

end