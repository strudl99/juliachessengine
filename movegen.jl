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
