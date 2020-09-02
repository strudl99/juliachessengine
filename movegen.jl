using Chess
include("pvtable.jl")
# MvvLVA move sort
#= piece_list = [PIECE_WP, PIECE_WN, PIECE_WB, PIECE_WR, PIECE_WQ, PIECE_WK,PIECE_BP, PIECE_BN, PIECE_BB, PIECE_BR, PIECE_BQ, PIECE_BK]
victim_scores = [100, 200, 300, 400, 500, 600, 100, 200, 300, 400, 500, 600, 0]

 =#

function count_pieces(chessboard)
    piece_count_prev = 0
    for square in range(1, stop = 64, step = 1)
        if pieceon(chessboard, Square(square)) != EMPTY
            piece_count_prev += 1
        end
    end
    return piece_count_prev
end

function capture_moves(chessboard::Board, all_moves, pv::Pv)::Array
    # println(all_moves)
    for (i, move) in enumerate(first.(all_moves))
        moveto = pieceon(chessboard, to(move))
        #quietMove
        if pv.killer_moves[1] == (move, 0) && pv.killer_moves[3] == pv.ply
            #println("KILLER1: ", pv.killer_moves[1])
            all_moves[i] = (move, 900000)
        elseif pv.killer_moves[2] == (move, 0) && pv.killer_moves[3] == pv.ply
            #println("KILLER2: ", pv.killer_moves[2])
            all_moves[i] = (move, 800000)
        else
            all_moves[i] = (move, pv.searchHistory[from(move).val, to(move).val])
        end
        if moveto != EMPTY
            if sidetomove(chessboard) == WHITE
                all_moves[i] = (move, 1000000 + pv.mvvlva_scores[ptype(moveto).val, ptype(moveto).val + 6]) 
            else
                all_moves[i] = (move, 1000000 + pv.mvvlva_scores[ptype(moveto).val + 6, ptype(moveto).val])
            end
        end
        
    end

    return all_moves
end

function only_capture_moves(chessboard::Board, pv::Pv)
    all_moves = moves(chessboard)
    
    capture_moves_list = Array{Tuple}(undef, 1)
    for (i, move) in enumerate(all_moves)
        moveto = pieceon(chessboard, to(move))
        if moveto != EMPTY
            if sidetomove(chessboard) == WHITE
                push!(capture_moves_list, (move, 1000000 + pv.mvvlva_scores[ptype(moveto).val, ptype(moveto).val + 6]) ) 
            else
                
                push!(capture_moves_list, (move, 1000000 + pv.mvvlva_scores[ptype(moveto).val + 6, ptype(moveto).val]))
            end        
        end
       
    end
    
    recycle!(all_moves)
    return capture_moves_list
end
function generate_moves(chessboard::Board, pv::Pv)
    temp_move = MOVE_NULL
    unsorted_moves = moves(chessboard)
    # println(unsorted_moves)
    all_moves = tuple.(unsorted_moves, 0) 
    cap = capture_moves(chessboard, all_moves, pv)
    recycle!(unsorted_moves)
    return cap
end
p = Dict("nodes" => 0)
function perft_strudl(b, depth)
    
    if depth == 0
        # println(nodes)
        return
    end
    all_moves = generate_moves(b)
    
    for i = 1:1:length(generate_moves(b))
        u = domove!(b, all_moves[i][1])
        perft_strudl(b, depth - 1)
        undomove!(b, u)
    end

end