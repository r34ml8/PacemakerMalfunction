using Test

author = "0"
path = "C:\\Users\\user\\course\\STDECGDB"

function count_table(fn_array::Vector{String}, malf::Vector{Vector{String}})
    tp = 0
    tn = 0
    fp = 0
    fn = 0
    for i in eachindex(fn_array)
        filepath_hdr = joinpath(path, "bin", fn_array[i] * ".hdr")
        filepath_json = joinpath(path, "mkp", fn_array[i] * "." * author, fn_array[i] * ".json")
        _, stimissues = PM.pacemaker_analyze(filepath_hdr, filepath_json)
        for stimissue in stimissues
            if stimissue.issue in malf[i]
                if true in stimissue
                    tp += 1
                else
                    fn += 1
                end
            else
                if true in stimissue
                    fp += 1
                else
                    tn += 1
                end
            end
        end
    end
    ppv = tp/(tp+fp)
    npv = tn/(fn+tn)
    se = tp/(tp+fn)
    sp = tn/(fp+tn)
    return ppv, npv, se, sp
end






















