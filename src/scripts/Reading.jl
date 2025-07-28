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
    _, hdrstruct = FileUtils.readhdr_patient_exam(filepath_hdr)
    line = hdrstruct.stimulus
    data = split(line, " ")

    data_mode = data[1][1:3]
    _mode = 0

    if (data_mode == "DDD")
        _mode = 3
    elseif (data_mode == "AAI")
        _mode = 2
    else
        _mode = 1
    end
    
    _base = parse.(Int, split(data[2], "/"))
    _base = round.(60 * 1000 ./ _base)

    _intervalAV = (_mode == 3 && length(data) == 3) ? parse.(Int, split(data[3][4:end], "-")) : nothing

    return _mode, _base, _intervalAV
end