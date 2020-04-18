
using Chess
mutable struct Keys
    squareKeys::Array
    pieceKeys::Array
    sideKey::Int
    castleKey::Int
    # general variables

    nodes::Int
    
end

mutable struct Pv
    pv_table::Array
    PVSIZE::UInt
    history::Array
    repetition::Array
    mvvlva_scores::Array
    killer_moves::Array
end

function rand32()
    return rand(UInt32, 1)[1]
end

function generate_key()
    key = 0
    piece1 = rand32()
    piece2 = rand32()
    piece3 = rand32()

    key ⊻= piece1
    key ⊻= piece2
    key ⊻= piece3
    println("Key 1: ", key)
    key ⊻= piece1
    println("Key1 out key:", key)
    key = 0
    key ⊻= piece2
    key ⊻= piece3
    println("no piece 1: ", key)
end


function InitHashKeys(keys::Keys)
    
    for i in 1:1:12
        append!(keys.pieceKeys, rand32())
    end
    for i in 1:1:64
        append!(keys.squareKeys, rand32())
    end
    keys.sideKey = rand32()
    keys.castleKey = rand32()
    return keys
end

function generate_pos_key(chessboard, keys)::Int
    final_key = 0

    for i in  1:1:64
        if pieceon(chessboard, Square(i)) != EMPTY
            if pieceon(chessboard, Square(i)) ==  PIECE_WP
                final_key ⊻= keys.squareKeys[i]
                final_key ⊻= keys.pieceKeys[1]
            end
            if pieceon(chessboard, Square(i)) == PIECE_WB
                final_key ⊻= keys.squareKeys[i]
                final_key ⊻= keys.pieceKeys[2]
            end
            if pieceon(chessboard, Square(i)) == PIECE_WN
                final_key ⊻= keys.squareKeys[i]
                final_key ⊻= keys.pieceKeys[3]
            end
            if pieceon(chessboard, Square(i)) == PIECE_WR
                final_key ⊻= keys.squareKeys[i]
                final_key ⊻= keys.pieceKeys[4]
            end
            if pieceon(chessboard, Square(i)) == PIECE_WQ
                final_key ⊻= keys.squareKeys[i]
                final_key ⊻= keys.pieceKeys[5]
            end
            if pieceon(chessboard, Square(i)) == PIECE_WK
                final_key ⊻= keys.squareKeys[i]
                final_key ⊻= keys.pieceKeys[6]
            end
            if pieceon(chessboard, Square(i)) ==  PIECE_BP
                final_key ⊻= keys.squareKeys[i]
                final_key ⊻= keys.pieceKeys[7]
            end
            if pieceon(chessboard, Square(i)) == PIECE_BB
                final_key ⊻= keys.squareKeys[i]
                final_key ⊻= keys.pieceKeys[8]
            end
            if pieceon(chessboard, Square(i)) == PIECE_BN
                final_key ⊻= keys.squareKeys[i]
                final_key ⊻= keys.pieceKeys[9]
            end
            if pieceon(chessboard, Square(i)) == PIECE_BR
                final_key ⊻= keys.squareKeys[i]
                final_key ⊻= keys.pieceKeys[10]
            end
            if pieceon(chessboard, Square(i)) == PIECE_BQ
                final_key ⊻= keys.squareKeys[i]
                final_key ⊻= keys.pieceKeys[11]
            end
            if pieceon(chessboard, Square(i)) == PIECE_BK
                final_key ⊻= keys.squareKeys[i]
                final_key ⊻= keys.pieceKeys[12]
            end
        end
    end
    if sidetomove(chessboard) == WHITE
        final_key ⊻= keys.sideKey
    end
    if cancastlekingside(chessboard, sidetomove(chessboard))
        final_key ⊻= keys.castleKey
    end
    if cancastlequeenside(chessboard, sidetomove(chessboard))
        final_key ⊻= keys.castleKey
    end

    return final_key
end

function Init_Pv_Table(pv::Pv)
    for i in 1:1:64
        push!(pv.history, MOVE_NULL)
    end
   
    for i in  1:1:pv.PVSIZE
        push!(pv.pv_table, Dict("move" => MOVE_NULL::Move,
            "posKey" => 0, "score" => 0, "depth" => 0, "flags" => ""))
    end
    return pv
end


function probe_Pv_Table(chessboard, keys::Keys, pvtable::Pv)::Move
    gameboard_key = generate_pos_key(chessboard, keys)
    index = (gameboard_key % pvtable.PVSIZE) + 1
    if gameboard_key in pvtable.pv_table[index]["posKey"]
        return pvtable.pv_table[index]["move"]
    end
    return MOVE_NULL
end

function store_Pv_Move(chessboard, move, score, flags, depth,  keys::Keys, pvtable::Pv)
    gameboard_key = generate_pos_key(chessboard, keys)

    index = (gameboard_key % pvtable.PVSIZE) + 1

    #= if pv_table[index]["posKey"] == 0
        global new_write += 1
    else
        global over_write += 1
    end =#

    pvtable.pv_table[index]["posKey"] = gameboard_key
    pvtable.pv_table[index]["move"] = move
    pvtable.pv_table[index]["score"] = score
    pvtable.pv_table[index]["flags"] = flags
    pvtable.pv_table[index]["depth"] = depth
    

end

function probe_hash_entry(chessboard, score, alpha, beta, depth, pv::Pv, key::Keys)::Tuple{Bool,Int,Move}
    gameboard_key = generate_pos_key(chessboard, key)
    index = (gameboard_key % pv.PVSIZE) + 1
    move = MOVE_NULL
    if gameboard_key in pv.pv_table[index]["posKey"]
        move = pv.pv_table[index]["move"]
        if pv.pv_table[index]["depth"] >= depth
            
            # global hashtablehit += 1
            @assert pv.pv_table[index]["depth"] > 0
            score = pv.pv_table[index]["score"]
            if pv.pv_table[index]["flags"] == "HFALPHA" && score <= alpha
                score = alpha
                return true, score, move
            elseif pv.pv_table[index]["flags"] == "HFBETA" && score >= beta
                score = beta
                return true, score, move
            elseif pv.pv_table[index]["flags"] == "HFEXACT"
                return true, score, move
            end

        end
    end
    return false, 0, move
end

function clearPvTable(pv::Pv)
    for i in  1:1:pv.PVSIZE
        # pv_table[i]["posKey"] = 0
        # pv_table[i]["move"] = MOVE_NULL::Move
        pv.pv_table[i]["score"] = 0
        pv.pv_table[i]["flags"] = 0
        pv.pv_table[i]["depth"] = 0
    end

    

end
function clear_search(pv::Pv) 
    for i in 1:1:64
        pv.history[i] = MOVE_NULL
    end
end
function get_history(depth, chessboard, key::Keys, pv::Pv)

    count = 0
    move = probe_Pv_Table(chessboard, key, pv)
    undoarray = []
    while move !== nothing && count <= depth
       # println(move)
        if move in moves(chessboard) && count <= 2

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