function classify_spikes(
    spikepos::Vector{Int64},
    qrs_bounds::Vector{UnitRange{Int64}},
    qrs_forms::Vector{String},
    mode::Int,
    fs::Float64 = 1000.0,
    radius::Float64 = 0.03,
    )

    form = fill("", length(spikepos))

    r = round(Int, radius*fs)

    for (i, pos) in enumerate(spikepos)
        if mode in (1, 3)
            prev_realised = false
            for (qrs, qrs_form) in zip(qrs_bounds, qrs_forms)
                if (pos > (first(qrs) - r)) && (pos < (last(qrs) + r)) # если стимул внутри qrs (с запасом r по краям)
                    if qrs_form == "X" # если стимул попал на событие X, не считаем его желудочковым
                        form[i] = "U"
                    elseif abs(first(qrs) - pos) < r # если стимул стоит в начале qrs (+-r)
                        form[i] = "VR" # желудочковый реализованный
                        prev_realised = true
                    else # если стимул внутри qrs, но не реализованный
                        if !prev_realised # если не было до него желудочкового реализованного стимула
                            form[i] = "VU" # то стимул без захвата
                        else # если был до желудочковый реализованный стимул
                            form[i] = "V" # пока не ставим реализованность. но это по сути страховочный?
                            # или то, что он страховочный, не отменяет того, что он без захвата?
                        end
                    end
                else
                    form[i] = "U"
                end
            end
        end

        # if mode in (2, 3) # если до сих не определили тип стимула,
        #     form[i] = "AN" # считаем его мо умолчанию предсердным нереализованным
        #     for (p, p_form) in zip(p_bounds, p_forms)
        #         if (pos > (first(p) - r)) && (pos < (last(p) + r)) # если попал внутрь p (с запасом r)
        #             if p_form == "Z"
        #                 form[i] = "A"
        #             else
        #                 form[i] = (abs(first(p) - pos) < r) ? "AR" : "AU" # то либо реализованный (если вначале), либо без захвата
        #             end
        #         end
        #     end
        # end
    end

    return form
end