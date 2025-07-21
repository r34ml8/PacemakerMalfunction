module EcgChar

import FileUtils.StdEcgDbAPI as API
include("Reading.jl")

mutable struct EcgRecord
    mode::Int #1 - V, 2 - A, 3 - A & V
    baseHRPoint::Int
    SAWB::BitArray
    VF::BitArray
    C::BitArray
    intervalAV::Union{Vector{Int}, Nothing}
    maxAV::Union{Int, Nothing}
    CC::Vector{Int}

    function EcgRecord(filename::String, author::String)
        mkpBase = Reading.get_data_from(filename, "mkp"; author)
        mode, baseHRPoint, intervalAV = Reading.get_data_from(filename, "hdr")
        
        maxAV = nothing

        if (!isnothing(intervalAV))
            maxAV = intervalAV[2]
        end

        SAWB, VF, C = BitArraySpawn(mkpBase.QRS_form)
        CC = CCArraySpawn(mkpBase.stimpos)
        
        return new(mode, baseHRPoint, SAWB, VF, C, intervalAV, maxAV, CC)
    end
    # function EcgRecord
end


# function EcgRecord()
#     return new(obj)
# end

# function EcgRecord(filename::String, author::String)
#     obj = EcgRecord()

#     mkpBase = Reading.get_data_from(filename; author=author)
#     obj.mode, obj.baseHRPoint, obj.intervalAV = Reading.get_data_from(filename; marker="hdr")

#     if (obj.intervalAV != Nothing)
#         obj.maxAV = obj.intervalAV[2]
#     end

#     obj.SAWB, obj.VF, obj.C = BitArraySpawn(mkpBase.QRS_form)
#     obj.CC = CCArraySpawn(mkpBase.stimpos)
    
#     return obj
# end

function BitArraySpawn(_QRS_form::Vector{String})
    n = length(_QRS_form)
    _SAWB = BitArray(undef, n)
    _VF = BitArray(undef, n)
    _C = BitArray(undef, n)
    
    for i in 1:n
        QRS = _QRS_form[i]
        if (QRS[1] == "V" || QRS[1] == "F")
            _VF[i] = 1
        elseif (QRS[1] == "C")
            _C[i] = 1
        else
            _SAWB[i] = 1
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