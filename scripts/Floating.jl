# module Floating

# include("EcgChar.jl")

# # @kwdef mutable struct BeforeComplexChar
# #     beforeVStimul::Union{Stimul, Nothing} = Nothing
# #     beforeAStimul::Union{Stimul, Nothing} = Nothing
# #     beforeSAWBComplex::Union{Int, Nothing} = Nothing
# #     beforeComplex::Union{Int, Nothing} = Nothing
# #     beforeComplexStart::Union{Int, Nothing} = Nothing
# #     beforeComplexWidth::Union{Int, Nothing} = Nothing
# #     beforeComplexRR::Union{Int, Nothing} = Nothing
# #     beforeStimulComplex::Union{Int, Nothing} = Nothing
# # end

# mutable struct ComplexChar
#     Base::Int
#     # B::Int
#     MaxBase::Int
#     # AV::Int #???
#     # IntervalAV::Int #???
#     # ComplexAV::Int
#     # SpikeCount::Int
#     # ZeroSpikeCount::Int #???
#     # NextVIndex::Union{Int, Nothing} = Nothing
#     RR::Int # пока принимаю RR равным B 
#     # NextComplexCC::Union{Int, Nothing} = Nothing
#     # CurComplexCCPos::Union{Int, Nothing} = nothing # ???
#     Complex::Int
#     CurrentZ::Bool = false
#     BeforeZ::Bool = false
#     # ST::Int

#     beforeVStimul::Union{Stimul, Nothing} = nothing
#     # beforeAStimul::Union{Stimul, Nothing} = Nothing
#     # beforeSAWBComplex::Union{Int, Nothing} = Nothing
#     beforeComplex::Union{Int, Nothing} = nothing
#     # beforeComplexStart::Union{Int, Nothing} = Nothing
#     # beforeComplexWidth::Union{Int, Nothing} = Nothing
#     beforeComplexRR::Union{Int, Nothing} = nothing
#     beforeStimulComplex::Union{Int, Nothing} = nothing

#     function ComplexChar(record::EcgChar.EcgRecord, mkpBase::API.StdMkp, _Complex::Int)
#         _Base = record.baseHRPoint

#         _RR = _Base
#         _MaxBase = _RR
#         _BeforeZ = false
#         if _Complex != 1
#             _RR = mkpBase.QRS_onset[_Complex - 1] - mkpBase.QRS_onset[_Complex]
#             _MaxBase = max(_Base, _RR)
#             _BeforeZ = mkpBase.QRS_form[_Complex - 1] == "Z" ? true : false
#         end

#         _CurrentZ = mkpBase.QRS_form[_Complex] == "Z" ? true : false

#         return new(_Base, _RR, _MaxBase, _Complex, _CurrentZ, _BeforeZ)
#     end
# end

# mutable struct StimulChar
#     Stimul::Int
#     StimulPosition::Int
#     StimulComplex::Int
#     StimulBeforeComplex::Union{Int, Nothing} = Nothing
#     StimulType::String
#     Complex::Union{ComplexChar, Nothing}
#     # StimulVerification::String #???

#     function StimulChar(record::EcgChar.EcgRecord, mkpBase::API.StdMkp, _ComplexChar::ComplexChar, _Stimul::Int)
#         _StimulPosition = mkpBase.stimpos[_Stimul]
#         _StimulComplex = 

#         return new(_Stimul, _StimulPosition)
#     end
# end

# end