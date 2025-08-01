import FileUtils

function get_data_from(filename, marker; author="", path="C:\\Users\\user\\course\\STDECGDB")
    if (marker == "mkp")
        filepath_json = joinpath(path, "mkp", filename * "." * author, filename * ".json")
        return FileUtils.read_stdmkp_json(filepath_json)
    elseif (marker == "hdr")
        filepath_hdr = joinpath(path, "bin", filename * ".hdr")
        return hdr_reading(filepath_hdr)
    end
end

function hdr_reading(filepath_hdr)
    _fs = FileUtils.readhdr(filepath_hdr).fs
    _, hdrstruct = FileUtils.readhdr_patient_exam(filepath_hdr)
    line = hdrstruct.stimulus
    data = split(line, " ")

    _mode = data[1]
    
    _base_vec = parse.(Int, split(data[2], "/"))
    _base_vec = round.(60 * 1000 ./ _base_vec)

    _base = length(_base_vec) == 2 ? (_base_vec[1], _base_vec[2]) : _base_vec[1]

    _intervalAV = nothing

    if _mode == "DDD" && length(data) == 3
        vec_interval = parse.(Int, split(data[3][4:end], "-"))
        _intervalAV = length(vec_interval) == 2 ? (vec_interval[1], vec_interval[2]) : vec_interval[1]
    end

    return EcgRecord(_fs, _mode, _base, _intervalAV)
end