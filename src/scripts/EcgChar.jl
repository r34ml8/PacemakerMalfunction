module EcgChar

import FileUtils.StdEcgDbAPI as API

mutable struct Complex
    index::Int
    Z::Bool
    pos_onset::Int
    pos_end::Int

    function Complex(mkpBase::API.StdMkp, _index::Int)
        _Z = mkpBase.QRS_form[_index] == "Z" ? true : false
        _pos_onset = mkpBase.QRS_onset[_index]
        _pos_end = mkpBase.QRS_end[_index]
        
        return new(_index, _Z, _pos_onset, _pos_end)
    end
end

mutable struct Stimul
    index::Int
    type::String
    position::Int
    complex::Complex
    satisfy::Bool

    function Stimul(mkpBase::API.StdMkp, _index::Int, complexes::Vector{Complex})
        _type = mkpBase.stimtype[_index]
        _position = mkpBase.stimpos[_index]
        _complex = findComplex(_position, complexes)

        return new(_index, _type, _position, _complex, true)
    end
end

#пока тут привязка к ближайшему
function findComplex(stimulPosition::Int, complexes::Vector{Complex})
    vectorDiff = abs.(stimulPosition .- getproperty.(complexes, :pos_onset))
    return complexes[argmin(vectorDiff)]
end

mutable struct EcgRecord
    mode::Int #1 - VVI, 2 - AAI, 3 - DDD
    base::Int
    complexes::Vector{Complex}
    stimuls::Vector{Stimul}

    function EcgRecord(mkpBase::API.StdMkp, _mode::Int, _base::Int)
        n = length(mkpBase.QRS_form)
        _complexes = Vector{Complex}(undef, n)
        for i in 1:n
            _complexes[i] = Complex(mkpBase, i)
        end

        n = length(mkpBase.stimtype)
        _stimuls = Vector{Stimul}(undef, n)
        for i in 1:n
            _stimuls[i] = Stimul(mkpBase, i, _complexes)
        end
        
        return new(_mode, _base, _complexes, _stimuls)
    end
end

function findPrevComplex(stimul::Stimul, record::EcgRecord)
    i = stimul.complex.index
    return i > 1 ? record.complexes[i - 1] : nothing
end

include("MalfunctionVVI.jl")

# function BitArraySpawn(n::Int, _QRS_form::Vector{String})
#     _SAWB = BitArray(undef, n)
#     _VF = BitArray(undef, n)
#     _C = BitArray(undef, n)
    
#     for i in 1:n
#         QRS = _QRS_form[i]
#         println(QRS[1])
#         if (QRS[1] == 'V') || (QRS[1] == 'F')
#             _VF[i] = 1
#             println("true")
#         elseif QRS[1] == 'C'
#             _C[i] = 1
#         else
#             _SAWB[i] = 1
#             println("false")
#         end
#     end

#     return _SAWB, _VF, _C
# end

# function CCArraySpawn(_stimpos::Vector{Int})
#     n = length(_stimpos) - 1

#     _CC = zeros(n)
#     for i in 1:n
#         _CC[i] = _stimpos[i + 1] - _stimpos[i]
#     end
    
#     return _CC
# end

end