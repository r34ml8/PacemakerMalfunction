using Test

XLSX.writetable("103019_2.xlsx", PM.pacemaker_analyze(joinpath(@__DIR__, "files", "103019_2.hdr"), joinpath(@__DIR__, "files", "103019_2.json")))
XLSX.writetable("oxst003269_2.xlsx", PM.pacemaker_analyze("files/oxst003269_2.hdr", "files/oxst003269_2.json"))


println(PM.pacemaker_analyze(joinpath(@__DIR__, "files", "103019_2.hdr"), joinpath(@__DIR__, "files", "103019_2.json")))
println(PM.pacemaker_analyze(joinpath(@__DIR__, "files", "oxst003269_2.hdr"), joinpath(@__DIR__, "files", "oxst003269_2.json")))























#TODO:
# 1. выбрать самые ужасные записи (пусть будут по две)
# 2. составить референтные таблицы malf.xlsx на глаз
# 3. экспортировать в csv
# 4. добавить их в files (а также jsonы и hdrы)
# 5. прочитать их в датафреймы
# 6. прогнать jsonы и hdrы через pacemaker_analyze()
# 7. сравнить
# 8. считать статистики

# 103019_2 oxst003269_2