using Chess
include("pvtable.jl")
# MvvLVA move sort
piece_list = [PIECE_WP, PIECE_WN, PIECE_WB, PIECE_WR, PIECE_WQ, PIECE_WK,PIECE_BP, PIECE_BN, PIECE_BB, PIECE_BR, PIECE_BQ, PIECE_BK]
victim_scores = [100, 200, 300, 400, 500, 600, 100, 200, 300, 400, 500, 600, 0]
mvvlva_scores = zeros(12, 12)
function init_mvvlva()
    for (i, attacker) in enumerate(piece_list)
        for (j, victim) in enumerate(piece_list)
            if attacker == piece_list[i] && victim == piece_list[j]
                mvvlva_scores[i, j] = victim_scores[i] + 6 - (victim_scores[j] / 100)
            end
        end
    end
end
function count_pieces(chessboard)
    piece_count_prev = 0
    for square in range(1, stop = 64, step = 1)
        if pieceon(chessboard, Square(square)) != EMPTY
            piece_count_prev += 1
        end
    end
    return piece_count_prev
end

function capture_moves(chessboard::Board, all_moves)
    # println(all_moves)
    for (i, move) in enumerate(first.(all_moves))
        moveto = pieceon(chessboard, to(move))
        if moveto != EMPTY
            if sidetomove(chessboard) == WHITE
                all_moves[i] = (move, 1000000 + mvvlva_scores[ptype(pieceon(chessboard, to(move))).val, ptype(pieceon(chessboard, from(move))).val + 6]) 
            else
                all_moves[i] = (move, 1000000 + mvvlva_scores[ptype(pieceon(chessboard, to(move))).val + 6, ptype(pieceon(chessboard, from(move))).val])
            end
        end
        if killer_moves[1] == (move, 0)
            # println("KILLER")
            all_moves[i] = (move, 900000)
        elseif killer_moves[2] == (move, 0)
            all_moves[i] = (move, 800000)
        end
    end

    return all_moves
end

function only_capture_moves(chessboard::Board)

    all_moves = moves(chessboard)
    capture_moves = tuple.(MoveList(20), 0)
    for move in all_moves
        moveto = pieceon(chessboard, to(move))
        if moveto != EMPTY
            if sidetomove(chessboard) == WHITE
                push!(capture_moves, (move, 1000000 + mvvlva_scores[ptype(pieceon(chessboard, to(move))).val, ptype(pieceon(chessboard, from(move))).val + 6])) 
            else
                push!(capture_moves, (move, 1000000 + mvvlva_scores[ptype(pieceon(chessboard, to(move))).val + 6, ptype(pieceon(chessboard, from(move))).val]))
            end        
        end
       
    end
    
    recycle!(all_moves)
    return capture_moves
end
function generate_moves(chessboard::Board)
    temp_move = MOVE_NULL
    unsorted_moves = moves(chessboard)
    # println(unsorted_moves)
    all_moves = tuple.(unsorted_moves, 0) 
    cap = capture_moves(chessboard, all_moves)
    recycle!(unsorted_moves)
    return cap
end

