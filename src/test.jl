# using DataFrames
include("PacemakerMalfunction.jl")
import PacemakerMalfunction as PM

filenames_array = readlines("C:\\Users\\user\\course\\STDECGDB\\dbstate\\#stim.txt")
author = "v2_0_0_dev"
path = "C:\\Users\\user\\course\\STDECGDB"

vvi_fn_arr = String[]

for fn in filenames_array
    m, _, _ = PM.get_data_from(fn, "hdr")
    if m == 1
        push!(vvi_fn_arr, fn)
    end
end

# filename = "ME1299130220184331_3"

fn = vvi_fn_arr[4]

println(fn)
mkpBase = PM.get_data_from(fn, "mkp"; author)
PM.mode, PM.base, _ = PM.get_data_from(fn, "hdr")
println(PM.base)
PM.complexes, PM.stimuls = PM.baseParams(mkpBase, PM.mode)
# _, hdrstruct = Reading.get_data_from(filenames_array[5], marker="hdr")
PM.analyzeVVI()
println()

PM.stimuls[5].complex.position
PM.stimuls[5].position

# supertype(Int)

# PM.mode
for fn in vvi_fn_arr
    println(fn)
    mkpBase = PM.get_data_from(fn, "mkp"; author)
    PM.mode, PM.base, _ = PM.get_data_from(fn, "hdr")
    println(PM.base)
    PM.complexes, PM.stimuls = PM.baseParams(mkpBase, PM.mode)
# _, hdrstruct = Reading.get_data_from(filenames_array[5], marker="hdr")
    PM.analyzeVVI()
    println()
end


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

