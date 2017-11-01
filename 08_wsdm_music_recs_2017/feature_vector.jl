function feature_vector!(fvec, fencode, features, user, item, event)
    i = 1; for feature in features 
        i = feature(fvec, fencode, i, user, item, event)
    end
    i-1
end

function fcity(fvec, fencode, i, user, item, event)
    fenc(fvec, fencode, i, user, :city)
end

function fbd(fvec, fencode, i, user, item, event)
    fenc(fvec, fencode, i, user, :bd)
end

function fregvia(fvec, fencode, i, user, item, event)
    fenc(fvec, fencode, i, user, :registered_via)
end

function freginit(fvec, fencode, i, user, item, event)
end

function fregexp(fvec, fencode, i, user, item, event)
end

function fgenre(fvec, fencode, i, user, item, event)
    fenc(fvec, fencode, i, item, :genre_ids)
end

function flang(fvec, fencode, i, user, item, event)
    fenc(fvec, fencode, i, item, :language)
end

function f(fvec, fencode, i, user, item, event)
end

# Help Functions

function fenc(fvec, fencode, i, entity, field)
    strfield = string(field)
    idx::Int = get(fencode[strfield], string(entity[1,field]), -1)
    idx >= 0 && (fvec[i+idx] = 1)
    i + length(fencode[strfield])
end
