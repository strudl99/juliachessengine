
using Chess
mutable struct Keys
    nodes::Int32
end

 @enum FLAGS begin
    HFALPHA
    HFBETA
    HFEXACT
end

mutable struct Pv
    PVSIZE::UInt
    pv_table::Array{Dict{String,Int128}, 1}
    history::Array
    repetition::Array{Int128, 1}
    mvvlva_scores::Array{Int64,2}
    killer_moves::Array{Move, 2}
    index_rep::Int
    how_many_reps::Int
    ply::Int
    hisPly::Int
    searchHistory::Array{Int64,2}
    white_passed_mask::Array{SquareSet, 1}
    black_passed_mask::Array{SquareSet, 1}
    isoloni_mask::Array{SquareSet, 1}
    moveList::MoveList
    side
    INF::Int
    MATE::Int
    debug::Bool
end
function initBitmask(pv)
    ranks = [SS_RANK_1, SS_RANK_2, SS_RANK_3,SS_RANK_4, SS_RANK_5, SS_RANK_6, SS_RANK_7, SS_RANK_8]
    files = [SS_FILE_A, SS_FILE_B, SS_FILE_C, SS_FILE_D, SS_FILE_E, SS_FILE_F, SS_FILE_G, SS_FILE_H]
    for i = 1:1:56
        push!(pv.white_passed_mask, SquareSet())
    end
    
    outerindex = 1
    
    for i = 1:1:7
        minusRank = SquareSet()
        for k = 1:1:i
            minusRank = union(minusRank, ranks[k])
        end
        for j = 1:1:2
            pv.white_passed_mask[outerindex] = union(pv.white_passed_mask[outerindex], files[j] - minusRank)
        end
        outerindex += 1
        for l = 1:1:6
            for j = l:1:l+2
                pv.white_passed_mask[outerindex] = union(pv.white_passed_mask[outerindex], files[j] - minusRank)
            end
            outerindex += 1
        end
        for j = 7:1:8
            pv.white_passed_mask[outerindex] = union(pv.white_passed_mask[outerindex], files[j] - minusRank)
        end
        outerindex += 1
    end

    for i = 1:1:56
        push!(pv.black_passed_mask, SquareSet())
    end
    
    outerindex = 1
    
    for i = 8:-1:2
        minusRank = SquareSet()
        for k = 8:-1:8-(8-i)
            minusRank = union(minusRank, ranks[k])
        end
        for j = 1:1:2
            pv.black_passed_mask[outerindex] = union(pv.black_passed_mask[outerindex], files[j] - minusRank)
        end
        outerindex += 1
        for l = 1:1:6
            for j = l:1:l+2
                pv.black_passed_mask[outerindex] = union(pv.black_passed_mask[outerindex], files[j] - minusRank)
            end
            outerindex += 1
        end
        
        
        

        for j = 7:1:8
            pv.black_passed_mask[outerindex] = union(pv.black_passed_mask[outerindex], files[j] - minusRank)
        end
        outerindex += 1
    end

    for i = 1:1:56
        push!(pv.isoloni_mask, SquareSet())
    end

    outerindex = 1
    for j = 1:1:7
        pv.isoloni_mask[outerindex] = SS_FILE_B
        outerindex += 1
        for i = 1:1:6
            pv.isoloni_mask[outerindex] = union(files[i], files[i+2])
            outerindex += 1
        end
        pv.isoloni_mask[outerindex] = SS_FILE_G
        outerindex += 1
    end
end

function Init_Pv_Table(pv::Pv)
    for i in 1:1:64
        push!(pv.history, MOVE_NULL)
    end
    for i in 1:1:500
        push!(pv.repetition, 0)
    end
    initBitmask(pv)
    pv.searchHistory = zeros(Int32,64,64)
    for i in 1:1:length(pv.repetition)
        pv.repetition[i] = 0
    end
    for i in  1:1:pv.PVSIZE
        push!(pv.pv_table, Dict("move" => 0,
            "posKey" => 0, "score" => 0, "depth" => 0, "flags" => -1))
    end
    return pv
end

function probe_Pv_Table(chessboard, keys::Keys, pvtable::Pv)::Move
    gameboard_key = chessboard.key
    index = (gameboard_key % pvtable.PVSIZE) + 1
    if gameboard_key in pvtable.pv_table[index]["posKey"]
        return Move(pvtable.pv_table[index]["move"])
    end
    return MOVE_NULL
end
global mutex = Threads.Condition()
function store_Pv_Move(chessboard, move, score, flags::FLAGS, depth,  keys::Keys, pvtable::Pv)
    

    gameboard_key = chessboard.key
    index = (gameboard_key % pvtable.PVSIZE) + 1

    @assert index >= 1 && index <= pvtable.PVSIZE
    @assert depth >= 1 && depth <= 20
    @assert flags == HFALPHA || flags == HFBETA || flags == HFEXACT
    @assert score >= -pvtable.INF  && score <= pvtable.INF 
    @assert pvtable.ply >= 0 && pvtable.ply <= 20

    if pvtable.debug
        if pvtable.pv_table[index]["posKey"] == 0
            global new_write += 1
        else
            global over_write += 1
        end 
    end
    ## wie functioniert es nochmal
    if score > pvtable.INF - 20
        score += pvtable.ply
    elseif score < -(pvtable.INF - 20)
        score -= pvtable.ply
    end

    pvtable.pv_table[index]["posKey"] = gameboard_key
    pvtable.pv_table[index]["move"] = move.val
    pvtable.pv_table[index]["score"] = score
    pvtable.pv_table[index]["flags"] = Int(flags)
    pvtable.pv_table[index]["depth"] = depth

end

function clear_hash_table(pv::Pv)
    for i in  1:1:pv.PVSIZE
        pv.pv_table[i]["posKey"] = 0
        pv.pv_table[i]["move"] = 0
        pv.pv_table[i]["score"] = 0
        pv.pv_table[i]["flags"] = 0
        pv.pv_table[i]["depth"] = 0
    end
end

function probe_hash_entry(chessboard, score, alpha, beta, depth, pv::Pv, key::Keys)::Tuple{Bool,Int,Move}
    
    
    gameboard_key = chessboard.key
    index = (gameboard_key % pv.PVSIZE) + 1

    @assert index >= 1 && index <= pv.PVSIZE
    @assert depth >= 1 && depth <= 20
    @assert alpha < beta
    @assert alpha >= -pv.INF  && alpha <= pv.INF 
    @assert beta >= -pv.INF  && beta <=pv.INF 
    @assert score >= -pv.INF  && score <= pv.INF 
    @assert pv.ply >= 0 && pv.ply <= 20


    move = MOVE_NULL::Move
    if gameboard_key in pv.pv_table[index]["posKey"]
        move = Move(pv.pv_table[index]["move"])
        if pv.pv_table[index]["depth"] >= depth
            if pv.debug
                global hashtablehit += 1
            end
            flagEntry = FLAGS(pv.pv_table[index]["flags"])
            @assert pv.pv_table[index]["depth"] >= 1 && pv.pv_table[index]["depth"] <= 20
            @assert flagEntry == HFALPHA || flagEntry == HFBETA || flagEntry == HFEXACT
            score = pv.pv_table[index]["score"]
            if score > pv.INF  - 20
                score -= pv.ply
            elseif score < -(pv.INF - 20)
                score += pv.ply
            end

            if flagEntry == HFALPHA && score <= alpha
                score = alpha
                return true, score, move
            elseif flagEntry == HFBETA && score >= beta
                score = beta
                return true, score, move
            elseif flagEntry == HFEXACT
                return true, score, move
            end

        end
    end
    return false, 0, move     
end
function clear_search(pv::Pv) 
    for i in 1:1:length(pv.history)
        pv.history[i] = MOVE_NULL
    end
    clear_hash_table(pv)
    for i in 1:1:length(pv.killer_moves)
        pv.killer_moves[i] = Move(0000)
    end
    for i in 1:1:length(pv.searchHistory)
        pv.searchHistory[i] = 0
    end
    
end
function get_history(depth, chessboard, key::Keys, pv::Pv)

    count = 0
    move = probe_Pv_Table(chessboard, key, pv)
    undoarray = []
    while move !== nothing && count <= depth
       # println(move)
        if move in moves(chessboard)
            count += 1
            u = domove!(chessboard, move)
            push!(undoarray, u)
            pv.history[count] = move
        else
            break
        end
        move = probe_Pv_Table(chessboard, key, pv)

    end
    while count > 0
        undomove!(chessboard, undoarray[count])
        count -= 1
    end

end 