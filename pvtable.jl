pieceKeys = []
sideKey = 0
pv_table = []
function InitHashKeys()
    for i in 1:1:64
        push!(pieceKeys, rand32())
    end

    global sideKey = rand32()

end

function generate_pos_key(chessboard)
    final_key = 0

    for i in  1:1:64
        if pieceon(chessboard, Square(i)) != EMPTY
            final_key ⊻= pieceKeys[i]
        end
    end
    if sidetomove(chessboard) == WHITE
        final_key ⊻= sideKey
    end

    return final_key
end

function Init_Pv_Table()
    for i in  1:1:10000
        push!(pv_table, Dict("move" => MOVE_NULL::Move,
            "posKey" => 0))
    end
end

function probe_Pv_Table(chessboard)
    gameboard_key = generate_pos_key(chessboard)
    index = (gameboard_key % 10000) + 1
    if gameboard_key in pv_table[index]["posKey"]
        return pv_table[index]["move"]
    end
    return nothing
end

function store_Pv_Move(chessboard, move)
    gameboard_key = generate_pos_key(chessboard)
    index = (gameboard_key % 10000) + 1
    pv_table[index]["posKey"] = gameboard_key
    pv_table[index]["move"] = move

end

function test(chessboard, move)
    InitHashKeys()
    Init_Pv_Table()
    store_Pv_Move(chessboard, move)
end

function clearPvTable()
    for i in  1:1:10000
        pv_table[i]["posKey"] = 0
        pv_table[i]["move"] = MOVE_NULL::Move
    end
end