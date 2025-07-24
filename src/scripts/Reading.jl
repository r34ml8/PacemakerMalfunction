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
    mode = 0

    if (data_mode == "DDD")
        mode = 3
    elseif (data_mode == "AAI")
        mode = 2
    else
        mode = 1
    end

    base = parse(Int, split(data[2], "/")[1])
    base = round(base / 60 * 1000)

    intervalAV = (mode == 3 && length(data) == 3) ? parse.(Int, split(data[3][4:end], "-")) : nothing

    return mode, base, intervalAV
end