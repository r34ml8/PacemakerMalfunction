# using DataFrames
include("PacemakerMalfunction.jl")
import PacemakerMalfunction as PM
import DataFrames as DF
import XLSX
using FileUtils

filenames_array = readlines("C:\\Users\\user\\course\\STDECGDB\\dbstate\\#stim.txt")
author = "v2_0_0_dev"
path = "C:\\Users\\user\\course\\STDECGDB"

ddd_avt = String[]

for filen in filenames_array
    filepath_hdr = joinpath(path, "bin", filen * ".hdr")
    filepath_json = joinpath(path, "mkp", filen * "." * author, filen * ".json")
    try
        PM.get_data_from(filepath_json, "mkp")
        PM.get_data_from(filepath_hdr, "hdr")
        push!(ddd_avt, filen)
    catch e
        # println("Errorrr: ")
    end
end

function analyze(fn::String)
    println(fn)
    filepath_json = joinpath(path, "mkp", fn * "." * "0", fn * ".json")
    mkpBase = PM.get_data_from(filepath_json, "mkp")
    filepath_hdr = joinpath(path, "bin", fn * ".hdr")
    rec = PM.get_data_from(filepath_hdr, "hdr")
    QRSes, stimuls = PM.mkpSignals(mkpBase, rec)
    println(rec.base)
    PM.stimulClassifier(stimuls, QRSes, rec)
    # PM.analyzeVVI(stimuls, QRSes, rec.base, rec.fs)
    println()
    return QRSes, stimuls, getproperty.(stimuls, :type)
end

function markers(filen::String, t)
    filepath_json = joinpath(path, "mkp", filen * "." * "0", filen * ".json")
    mkp_ = FileUtils.read_stdmkp_json(filepath_json)

    newforms = t
    mkp_.stimtype = newforms
    mkp_.author = "res"
    mkpath(joinpath(path, "mkp", filen * "." * "res"))
    FileUtils.write_stdmkp_json(joinpath(path, "mkp", filen * "." * "res", filen * ".json"), mkp_)
end

analyze("00020489_2")

for fn in ddd_avt
    _, _, t = analyze(fn)
    println(t)
    markers(fn, t)
end

filepath_hdr = joinpath(path, "bin", ddd_avt[1] * ".bin")

ecg, h = read_bin_record(filepath_hdr)

println(ecg)
ecg

function read_bin_record(filepath::String, h::Union{TableHeader, Nothing} = nothing)
    if isnothing(h)
        h = readheader(first(splitext(filepath))*".hdr")
    end
    rawdata = FileUtils.readbin(filepath, h)
    data = FileUtils.Tables.columns(FileUtils.StructVector(rawdata)) |> collect
    # ch_data = [round.(x.*y.encoding.lsb, digits = 3) for (x,y) in zip(data, h.encodings)] # умножение всех каналов на их lsb
    # TODO: ограничиваю 3-мя символами после запятой - так и оставить?

    ch_data = [round.(x.*y.encoding.lsb) for (x,y) in zip(data, h.encodings)] # умножение всех каналов на их lsb И ОКРУГЛЕНИЕ ДО ЦЕЛЫХ МКВ

    return ch_data, h
end

function toXLSX(QRSes::Vector{PM.QRS}, stimuls::Vector{PM.Stimul})
    dfStimul = DF.DataFrame(stimuls)

    dfMalf = DF.DataFrame(getproperty.(stimuls, :malfunction))
    for col in names(dfMalf)
        dfMalf[!, col] = convert(Vector{Union{Bool, Nothing}}, dfMalf[!, col])
    end

    for i in 1:DF.nrow(dfMalf)
        for j in 1:DF.ncol(dfMalf)
            if !dfMalf[i, j]
                dfMalf[i, j] = nothing
            end
        end
    end

    _RR = Int64[]
    for stim in stimuls
        push!(_RR, QRSes[stim.QRS_index].RR)
    end
    dfRR = DF.DataFrame(RR = _RR)

    dfFinal = hcat(dfStimul[:, 1:4], dfRR, dfMalf)

    XLSX.writetable("stimuls.xlsx", dfFinal, overwrite=true)
end

vvi_fn_arr = String[]
aai_fn_arr = String[]

for fn in filenames_array
    filepath = joinpath(path, "bin", fn * ".hdr")
    rec = PM.get_data_from(filepath, "hdr")
    if rec.mode[1:3] == "VVI"
        push!(vvi_fn_arr, fn)
    elseif rec.mode[1:3] == "AAI"
        println(fn)
        push!(aai_fn_arr, fn)
    end
end

QRSes, stimuls, t = analyze(aai_fn_arr[3])
toXLSX(QRSes, stimuls)


filen = "103019_2"
filepath_hdr = joinpath(path, "bin", filen * ".hdr")
filepath_json = joinpath(path, "mkp", filen * "." * author, filen * ".json")
PM.pacemaker_analyze(filepath_hdr, filepath_json)


XLSX.writetable("103019_2.xlsx", PM.pacemaker_analyze("../test/files/103019_2.hdr", "../test/files/103019_2.json"))
XLSX.writetable("oxst003269_2.xlsx", PM.pacemaker_analyze("../test/files/oxst003269_2.hdr", "../test/files/oxst003269_2.json"))




vect = [1, 2, 3]
df = DF.DataFrame(Values = vect)


# q, s, t = analyze(f)
# markers(f, t)

# toXLSX(q, s)
# println(analyze("30018678_1"))



XLSX.writetable("stimtype.xlsx", DF.DataFrame(type=analyze("30018678_1")))
vec_stimpos = analyze("30018678_1")
to
vec_SS = [vec_stimpos[i] - vec_stimpos[i - 1] for i in 2:25]
print(vec_SS)

fn = "st003045_1"
# filename = "ME1299130220184331_3"

# fn = vvi_fn_arr[8]

# println(fn)
# mkpBase = PM.get_data_from(fn, "mkp"; author)
# PM.mode, PM.base, _ = PM.get_data_from(fn, "hdr")
# println(PM.base)
# PM.complexes, PM.stimuls = PM.baseParams(mkpBase, PM.mode)
# println(PM.base)
# _, hdrstruct = Reading.get_data_from(filenames_array[5], marker="hdr")
# PM.analyzeVVI()
# println()

# PM.stimuls[5].complex.position
# PM.stimuls[5].position

# supertype(Int)

# PM.mode
for fn in vvi_fn_arr
    println(fn)
    mkpBase = PM.get_data_from(fn, "mkp"; author)
    rec = PM.get_data_from(fn, "hdr")
    println(rec.base)
    QRSes, stimuls = PM.mkpSignals(mkpBase, rec)
    PM.analyzeVVI(stimuls, QRSes, rec.base, rec.fs)
    println()
end

hg = (122, 49, 93)
typeof(hg)
hg = hg .- 5


a = "1"
a = parse.(Int, a)
typeof(a)

print(1, " ")
print(2)

abstract type child end

struct daughter <: child
    age
end

struct son <: child
    age
end

d = daughter(5)
s = son(2)

function showAge(ch::child)
    println(ch.age)
end

showAge(s)

a = 3
_v = [a - 1, a + 1]

_v .-= 1

g = a > 5

mkpBase.recordname
Int(5.0)
i = 1.5
if !(i in (1, 2))
    println(i)
end

n = 5
for i in 0:-1:1
    println(i)
end

# hdrstruct.stimulus
# hdrstruct.fs_base

# _vec = abs.(mkpBase.stimpos[1] .- mkpBase.QRS_onset)
# argmax(_vec)


_vec = getproperty.(getproperty.(record.stimuls, :complex), :index)

println.(getproperty.(record.stimuls, :index), " ", getproperty.(getproperty.(record.stimuls, :complex), :index))

# println.(mkpBase.QRS_onset)
# mkpBase.QRS_end
# println.(mkpBase.stimpos)
# n = length(mkpBase.QRS_form)
# _SAWB = BitArray(undef, n)
# _VF = BitArray(undef, n)
# _C = BitArray(undef, n)
    
# for i in 1:n
#     QRS = mkpBase.QRS_form[i]
#     println(QRS[1])
#     if (QRS[1] == "V") || (QRS[1] == "F")
#         _VF[i] = 1
#         println("true")
#     elseif QRS[1] == "C"
#         _C[i] = 1
#     else
#         _SAWB[i] = 1
#         println("false")
#     end
# end

# QRS = mkpBase.QRS_form[2]
#     println(QRS[1])
#     if (QRS[1] == 'V') || (QRS[1] == 'F')
#         _VF[i] = 1
#         println("true")
#     end


# filepath_json = joinpath(path, "mkp", a[5] * "." * author, a[5] * ".json")
# filepath_hdr = joinpath(path, "bin",  a[5] * ".hdr")
# filepath_bin = joinpath(path, "bin", a[5] * ".bin")

# mkp_example = FileUtils.read_stdmkp_json(filepath_json)
# mkp_df = DataFrame(mkp_example)
# hdr_example = FileUtils.readhdr(filepath_hdr)

# table_example = FileUtils.readtable(filepath_hdr, filepath_bin)
# mkpexample.stimtype

# function _hdr_reading(i)
#     filepath_hdr = joinpath(path, "bin",  a[i] * ".hdr")
#     return Reading.hdr_reading(filepath_hdr)
# end

# _hdr_reading(7)

