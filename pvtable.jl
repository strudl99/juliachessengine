pieceKeys = []
squareKeys = []
sideKey = 0
pv_table = []
castle_key = 0
search_history = []
new_write = 0
over_write = 0
hashtablehit = 0
hashcut = 0
PVSIZE = 0x10000 * 15 

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


function InitHashKeys()
    for i in 1:1:12
        push!(pieceKeys, rand32())
    end
    for i in 1:1:64
        push!(squareKeys, rand32())
    end
    global sideKey = rand32()
    global castle_key = rand32()

end

function generate_pos_key(chessboard)
    final_key = 0

    for i in  1:1:64
        if pieceon(chessboard, Square(i)) != EMPTY
            if pieceon(chessboard, Square(i)) ==  PIECE_WP
                final_key ⊻= squareKeys[i]
                final_key ⊻= pieceKeys[1]
            end
            if pieceon(chessboard, Square(i)) == PIECE_WB
                final_key ⊻= squareKeys[i]
                final_key ⊻= pieceKeys[2]
            end
            if pieceon(chessboard, Square(i)) == PIECE_WN
                final_key ⊻= squareKeys[i]
                final_key ⊻= pieceKeys[3]
            end
            if pieceon(chessboard, Square(i)) == PIECE_WR
                final_key ⊻= squareKeys[i]
                final_key ⊻= pieceKeys[4]
            end
            if pieceon(chessboard, Square(i)) == PIECE_WQ
                final_key ⊻= squareKeys[i]
                final_key ⊻= pieceKeys[5]
            end
            if pieceon(chessboard, Square(i)) == PIECE_WK
                final_key ⊻= squareKeys[i]
                final_key ⊻= pieceKeys[6]
            end
            if pieceon(chessboard, Square(i)) ==  PIECE_BP
                final_key ⊻= squareKeys[i]
                final_key ⊻= pieceKeys[7]
            end
            if pieceon(chessboard, Square(i)) == PIECE_BB
                final_key ⊻= squareKeys[i]
                final_key ⊻= pieceKeys[8]
            end
            if pieceon(chessboard, Square(i)) == PIECE_BN
                final_key ⊻= squareKeys[i]
                final_key ⊻= pieceKeys[9]
            end
            if pieceon(chessboard, Square(i)) == PIECE_BR
                final_key ⊻= squareKeys[i]
                final_key ⊻= pieceKeys[10]
            end
            if pieceon(chessboard, Square(i)) == PIECE_BQ
                final_key ⊻= squareKeys[i]
                final_key ⊻= pieceKeys[11]
            end
            if pieceon(chessboard, Square(i)) == PIECE_BK
                final_key ⊻= squareKeys[i]
                final_key ⊻= pieceKeys[12]
            end
        end
    end
    if sidetomove(chessboard) == WHITE
        final_key ⊻= sideKey
    end
    if cancastlekingside(chessboard, sidetomove(chessboard))
        final_key ⊻= castle_key
    end
    if cancastlequeenside(chessboard, sidetomove(chessboard))
        final_key ⊻= castle_key
    end

    return final_key
end

function Init_Pv_Table()
    global PVSIZE = 10000 
    for i in  1:1:PVSIZE
        push!(pv_table, Dict("move" => MOVE_NULL::Move,
            "posKey" => 0, "score" => 0, "depth" => 0, "flags" => ""))
    end
    
end

function Init_search_history()

    for i in 1:1:64
        push!(search_history, MOVE_NULL::Move)
    end
end

function probe_Pv_Table(chessboard)
    gameboard_key = generate_pos_key(chessboard)
    index = (gameboard_key % PVSIZE) + 1
    if gameboard_key in pv_table[index]["posKey"]
        return pv_table[index]["move"]
    end
    return nothing
end

function store_Pv_Move(chessboard, move, score, flags, depth)
    gameboard_key = generate_pos_key(chessboard)

    index = (gameboard_key % PVSIZE) + 1

    if pv_table[index]["posKey"] == 0
        global new_write += 1
    else
        global over_write += 1
    end

    pv_table[index]["posKey"] = gameboard_key
    pv_table[index]["move"] = move
    pv_table[index]["score"] = score
    pv_table[index]["flags"] = flags
    pv_table[index]["depth"] = depth
    

end

function probe_hash_entry(chessboard, score, alpha, beta, depth)
    gameboard_key = generate_pos_key(chessboard)
    index = (gameboard_key % PVSIZE) + 1
    move = nothing
    if gameboard_key in pv_table[index]["posKey"]
        move = pv_table[index]["move"]
        if pv_table[index]["depth"] >= depth
            
            global hashtablehit += 1
            @assert pv_table[index]["depth"] > 0
            score = pv_table[index]["score"]
            if pv_table[index]["flags"] == "HFALPHA" && score <= alpha
                score = alpha
                return true, score, move
            elseif pv_table[index]["flags"] == "HFBETA" && score >= beta
                score = beta
                return true, score, move
            elseif pv_table[index]["flags"] == "HFEXACT"
                return true, score, move
            end

        end
    end
    return false, 0, move
end

function clearPvTable()
    for i in  1:1:PVSIZE
        # pv_table[i]["posKey"] = 0
        # pv_table[i]["move"] = MOVE_NULL::Move
        pv_table[i]["score"] = 0
        pv_table[i]["flags"] = 0
        pv_table[i]["depth"] = 0
    end

    

end
function clear_search()
    global new_write = 0
    global over_write = 0
    global hashtablehit = 0
    global hashcut = 0
    for i in 1:1:64
        global search_history[i] = MOVE_NULL
    end
end
function get_history(depth,  chessboard)

    count = 0
    move = probe_Pv_Table(chessboard)
    undoarray = []
    while move !== nothing && count <= depth
       # println(move)
        if move in moves(chessboard)
            count += 1
            u = domove!(chessboard, move)
            push!(undoarray, u)
            search_history[count] = move
        else
            break
        end
        move = probe_Pv_Table(chessboard)

    end
    while count > 0
        undomove!(chessboard, undoarray[count])
        count -= 1
    end

end

function main()
    InitHashKeys()
    Init_Pv_Table()
    Init_search_history()
    
end