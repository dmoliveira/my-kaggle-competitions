#!/usr/bin/env julia
using DataFrames
using ProgressMeter
using JSON

include("feature_vector.jl")

function loadusers()::Dict
    df = readtable("data/input/members.csv")
    users = Dict{String,DataFrame}()
    @showprogress 1 "Loading Users..." for i=1:size(df,1)
        @inbounds users[df[i,:msno]] = df[i,:]
    end
    users
end

function loaditems()::Dict
    df = readtable("data/input/songs.processed.csv", nrows=-1)
    items = Dict{String,DataFrame}()
    @showprogress 1 "Loading items..." for i=1:size(df,1)
        @inbounds items[df[i,:song_id]] = df[i,:]
    end
    items
end

function build_dataframe(fencode, users, items, events)
    features = [fcity, fbd, fregvia, fgenre, flang]
    fvec = spzeros(100_000, 1)
    writer = open("data/dataframe/df01", "w")
    tevt, revt = 0,0
    @showprogress 1 "Computing Features..." for i=1:size(events,1)
        tevt += 1
        @inbounds user = get(users, events[i,:msno], nothing)
        if user != nothing
            @inbounds item = get(items, events[i,:song_id], nothing)
            if item != nothing
                revt += 1
                maxidx = feature_vector!(fvec, fencode, features, user, item, events[i,:])
                #fvec = sparse([1 0 1 0 1 0 1 1;]')
                @inbounds write_instance(writer, fvec, events[i,:target], maxidx)
                nonzeros(fvec) .= 0
                dropzeros!(fvec)
            end
        end
    end
    info("[$(now())] Events $revt/$tevt ($(round(revt/tevt*100,2))%)")
    flush(writer)
    close(writer)
end

function write_instance(writer, fvec, y, maxidx)
    rows = rowvals(fvec) 
    vals = nonzeros(fvec) 
    write(writer, "$y")
    lastrowidx = 0
    for j in nzrange(fvec, 1) 
       @inbounds lastrowidx = rows[j] 
       @inbounds write(writer, " $(lastrowidx-1):$(vals[j])")
    end 
    @inbounds lastrow = lastrowidx != maxidx? string(" ", maxidx, ":", fvec[end,1]) : ""
    write(writer, "$lastrow\n")
end

function main()
    t = now()
    println("")
    println("--Started DataFrame Generation")
    info("[$(now())] 1/5. Loading FEncoding...")
    fencode = JSON.parsefile("data/pretraining/fencode.json")
    info("[$(now())] 2/5. Loading Users...")
    users = loadusers()
    info("[$(now())] 3/5. Loading Items...")
    items = loaditems()
    info("[$(now())] 4/5. Loading Events...")
    events =  readtable("data/input/train.csv", nrows=-1)
    info("[$(now())] 5/5. Building DataFrames...")
    build_dataframe(fencode, users, items, events)
    elapsed = round(convert(Float64, Dates.value(now()-t)/60000),2)
    info("Elapsed Time: $(elapsed)m")
    info("-- Finished DataFrame Generation")
end

main()
