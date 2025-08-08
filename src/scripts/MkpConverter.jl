import FileUtils.StdEcgDbAPI as api
using Descriptors.Box51Desc
import PacemakerMalfunction as PM
using FileUtils

const ISSUE_CODE = Dict{String, Enum}(
    "hysteresis" => NodalConduction.Sensing.hysteresis,      # гистерезис
    "output_block" => NodalConduction.Sensing.output_block,  # блок выхода
    "no_capture" => NodalConduction.Sensing.no_capture,      # нарушение захвата
    "hypersensing" => NodalConduction.Sensing.hypersensing,  # гиперсенсинг
    "hyposensing" => NodalConduction.Sensing.hyposensing     # гипосенсинг
)

filenames_array = readlines("C:\\Users\\user\\course\\STDECGDB\\dbstate\\#stim.txt")
author = "0"
path = "C:\\Users\\user\\course\\STDECGDB"

vvi_fn_arr = String[]
aai_fn_arr = String[]





function mkpconverter(filen::String, mode::String)
    filepath_hdr = joinpath(path, "bin", filen * ".hdr")
    filepath_json = joinpath(path, "mkp", filen * "." * author, filen * ".json")
    stimtype, stimissues = PM.pacemaker_analyze(filepath_hdr, filepath_json)
    mkp = FileUtils.read_stdmkp_json(filepath_json)
    # Небольшой костыль для фонового ритма

    base_rhythm = BaseRhythm.Entity()
    base_rhythm.driver = BaseRhythm.Driver.pacing
    if mode[1:3] == "VVI"
        base_rhythm.pacing = BaseRhythm.Pacing.vent # зависит от режима стимуляции
    elseif mode[1:3] == "AAI"
        base_rhythm.pacing = BaseRhythm.Pacing.atrial
    elseif mode[1:3] == "DDD"
        base_rhythm.pacing = BaseRhythm.Pacing.dual
    end
    base_rhythm.mask = trues(length(mkp.QRS_onset))

    eventA = api.Event(base_rhythm, Ectopic.Entity[], NodalConduction.Entity[])
    eventV = api.Event(base_rhythm, Ectopic.Entity[], NodalConduction.Entity[])

    for event in stimissues
        if !iszero(count(event.mask)) # проверяем, что маска не пуста => событие есть на записи
            issue = NodalConduction.Entity()
            issue.mask = event.mask
            issue.sensing = ISSUE_CODE[event.issue]
            if event.channel == "V"
                push!(eventV.nodal_conduction, issue)
            elseif event.channel == "A"
                push!(eventA.nodal_conduction, issue)
            elseif event.channel == "V/A"
                push!(eventA.nodal_conduction, issue)
                push!(eventV.nodal_conduction, issue)
            end
        end
    end


    new_mkp = deepcopy(mkp)
    new_mkp.stimtype = stimtype
    new_mkp.events = [eventA]
    new_mkp.eventsV = [eventV]
    new_mkp.author = "res" # НЕ ЗАБЫВАЕМ УКАЗАТЬ АВТОРОМ СЕБЯ

    new_author = "res" # !!!
    path_ = api.generate_fullpath(joinpath(path, "mkp"), filen, new_author) # функция сама создаст нужные папки
    api.write_stdmkp_json(path_, new_mkp)
end


for fn in filenames_array
    filepath = joinpath(path, "bin", fn * ".hdr")
    rec = PM.get_data_from(filepath, "hdr")
    mkpconverter(fn, rec.mode)
    # if rec.mode[1:3] == "VVI"
    #     push!(vvi_fn_arr, fn)
    #     mkpconverter(fn, rec.mode)
    # elseif rec.mode[1:3] == "AAI"
    #     println(fn)
    #     push!(aai_fn_arr, fn)
    #     mkpconverter(fn, rec.mode)
    # end
end