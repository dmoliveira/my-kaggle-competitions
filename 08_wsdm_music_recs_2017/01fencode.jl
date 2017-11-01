#!/usr/bin/env julia 
using DataFrames
using ProgressMeter
using DataStructures
using JSON

doc"Get Users Encode."
function getusers_encode(input_filename)::Dict
    columns = [:city, :bd, :gender, :registered_via]
    get_encode(input_filename, columns)
end

doc"Get Items Encode."
function getitems_encode(input_filename)::Dict
    columns = [:genre_ids, :language]
    get_encode(input_filename, columns)
end

doc"Get Encode."
function get_encode(input_filename, columns)::Dict
    df = readtable(input_filename)
    fencode = DefaultDict{String,Set}(()-> Set{Any}())
    @showprogress 1 "Computing Encoding..." for i=1:size(df,1), column in columns 
        isna(df[i, column]) && continue
        if !(column in [:artist_name, :genre_ids])
            push!(fencode[string(column)], df[i, column])
        else
            for value in split(df[i, column], "|")
                push!(fencode[string(column)], value)
            end
        end
    end
    Dict(fencode)
end

function encode2ids(fencode)::Dict
    newfencode = Dict{String,Dict{Any,Int}}()
    for (encode, values) in fencode
        newfencode[encode] = Dict{Any,Int}()
        for (i, value) in enumerate(sort(collect(values)))
            newfencode[encode][value] = i
        end
    end
    newfencode
end

function main()
    println("")
    info("[$(now())]-- Start Encoding")
    info("[$(now())]\t1/4. User Encoding...")
    fencode = getusers_encode("data/members.csv")
    info("[$(now())]\t2/4. Item Encoding...")
    merge!(fencode, getitems_encode("data/songs.processed.csv"))
    info("[$(now())]\t3/4. Encode to Ids...")
    fencode = encode2ids(fencode)
    info("[$(now())]\t4/4. Writing Encoding...")
    writer = open("data/pretraining/fencode.json", "w")
    write(writer, JSON.json(fencode))
    flush(writer)
    close(writer)
    info("[$(now())]-- Finished Encoding\n")
end

main()
