module EcgChar

import FileUtils.StdEcgDbAPI as API
include("Reading.jl")

mutable struct EcgRecord
    mode::Int #1 - VVI, 2 - AAI, 3 - DDD
    baseHRPoint::Int
    SAWB::BitArray
    VF::BitArray
    C::BitArray
    intervalAV::Union{Vector{Int}, Nothing}
    maxAV::Union{Int, Nothing}
    CC::Vector{Int}
    complexes::Vector{Union{Complex, Nothing}}

    function EcgRecord(mkpBase::API.StdMkp, _mode::Int, _baseHRPoint::Int, _intervalAV::Union{Vector{Int}, Nothing})
        _maxAV = isnothing(_intervalAV) ? nothing : _intervalAV[2]

        n = length(_QRS_form)
        _SAWB, _VF, _C = BitArraySpawn(n, mkpBase.QRS_form)
        _CC = CCArraySpawn(mkpBase.stimpos)

        # _complexes = Union{Complex, Nothing}
        # TODO: генерация вектора комплексов
        
        return new(_mode, _baseHRPoint, _SAWB, _VF, _C, _intervalAV, _maxAV, _CC)
    end

end

function BitArraySpawn(n::Int, _QRS_form::Vector{String})
    _SAWB = BitArray(undef, n)
    _VF = BitArray(undef, n)
    _C = BitArray(undef, n)
    
    for i in 1:n
        QRS = _QRS_form[i]
        println(QRS[1])
        if (QRS[1] == 'V') || (QRS[1] == 'F')
            _VF[i] = 1
            println("true")
        elseif QRS[1] == 'C'
            _C[i] = 1
        else
            _SAWB[i] = 1
            println("false")
        end
    end

    return _SAWB, _VF, _C
end

function CCArraySpawn(_stimpos::Vector{Int})
    n = length(_stimpos) - 1

    _CC = zeros(n)
    for i in 1:n
        _CC[i] = _stimpos[i + 1] - _stimpos[i]
    end
    
    return _CC
end

end