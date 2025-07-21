using DataFrames
include("Reading.jl")
include("EcgChar.jl")

import FileUtils

filenames_array = readlines("C:\\Users\\user\\course\\STDECGDB\\dbstate\\#stim.txt")
author = "avt"
path = "C:\\Users\\user\\course\\STDECGDB"

# typeof(Reading.get_data_from(filenames_array[5], author))
_, hdrstruct = Reading.get_data_from(filenames_array[5], marker="hdr")

hdrstruct.stimulus
hdrstruct.fs_base

EcgChar.EcgRecord(filenames_array[5], author)

# filepath_json = joinpath(path, "mkp", a[5] * "." * author, a[5] * ".json")
# filepath_hdr = joinpath(path, "bin",  a[5] * ".hdr")
# filepath_bin = joinpath(path, "bin", a[5] * ".bin")

# mkp_example = FileUtils.read_stdmkp_json(filepath_json)
# mkp_df = DataFrame(mkp_example)
# hdr_example = FileUtils.readhdr(filepath_hdr)

# table_example = FileUtils.readtable(filepath_hdr, filepath_bin)
# mkpexample.stimtype

function _hdr_reading(i)
    filepath_hdr = joinpath(path, "bin",  a[i] * ".hdr")
    return Reading.hdr_reading(filepath_hdr)
end

_hdr_reading(6)