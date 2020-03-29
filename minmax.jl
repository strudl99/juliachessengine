using Chess, Chess.Book
include("eval.jl")

# function that goes through all moves and picks the best one with minmax algorithm

function calc_best_move(chessboard, depth, white_player, zug)
    # keinen "Folder" zugriff mehr nach zug 7 -> geschwindigkeitsoptimierung
    if zug < 8
        bookmove = nothing

        bookmove = pickbookmove(chessboard, "openings/carlsen.obk", minscore = 0.01, mingamecount = 10)
        if bookmove !== nothing
            return bookmove
        end
    end
    all_moves = sort_moves(chessboard)
    side = sidetomove(chessboard)
    best_move = nothing
    best_value = side == WHITE ? -1e8 : 1e8 
    if !haslegalmoves(chessboard)
        exit()
    end
    for move in all_moves
        u = domove!(chessboard, move)
        value = minimax(depth, chessboard, -1e8, 1e8, white_player)
        undomove!(chessboard, u)
        if side == WHITE && value > best_value
            best_value = value
            best_move = move
        elseif side == BLACK && value < best_value
            best_value = value
            best_move = move
        end

    end
    return best_move
end

# simmple minimax algorithm with alpha beta pruning

function minimax(depth, chessboard, alpha, beta, isMaximisingPlayer)
    if depth == 0
        return evaluate_board(chessboard)
    end
    leg = moves(chessboard)
    best_value = isMaximisingPlayer ? -1e8 : 1e8 
    if depth <= 2
        if length(leg) > 10
            leg = leg[1:10]
        end
    end
    for move in leg

        u = domove!(chessboard, move)
        value = minimax(depth - 1, chessboard, alpha, beta, !isMaximisingPlayer)
        if isMaximisingPlayer
            best_value = max(best_value, value)
            alpha = max(alpha, best_value)
        else
            best_value = min(best_value, value)
            beta = min(beta, best_value)
        end
        undomove!(chessboard, u)
        if beta <= alpha
            break
        end
    end
    return best_value
end