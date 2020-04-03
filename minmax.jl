using Chess, Chess.Book
include("eval.jl")

# isn't really working

function quiescence(alpha, beta, chessboard)
    all_moves = capture_moves(chessboard)
    score = evaluate_board(chessboard)
    if score >= beta
        return beta
    end
    if score > alpha
        alpha = score
    end
    if !isempty(all_moves)
        for move in all_moves
            u = domove!(chessboard, move)
            score = -quiescence(-beta, -alpha, chessboard)
            undomove!(chessboard, u)
            if score >= beta
                return beta
            end 
            if score > alpha
            
                alpha = score
            end
        end
        return alpha
    end
    return evaluate_board(chessboard)
end
# function that goes through all moves and picks the best one with minmax algorithm
function calc_best_move(chessboard, depth)

    bookmove = nothing

    bookmove = pickbookmove(chessboard, "openings/carlsen.obk", minscore = 0.01, mingamecount = 20)
    if bookmove !== nothing
        return bookmove
    end
    side = sidetomove(chessboard)
    current_depth = 0
    max_death = depth
    best_move = nothing
    while current_depth < max_death
        best_value = -1e8 
	
        current_depth += 1
        all_moves = sort_moves(chessboard)
        if depth >= 4
            if length(all_moves) > 20
                all_moves = all_moves[1:20]
            end
        end
        for move in all_moves
            u = domove!(chessboard, move)
            value = -negamax(current_depth, -1e8, 1e8, chessboard, side == WHITE ? -1 : 1)
            undomove!(chessboard, u)
            if (value > best_value)
                best_value = value
                best_move = move
            
      	     end
       	end
        println("info score cp ", best_value, " bestmove: ", best_move, " depth ", current_depth)
    end
    return best_move
end

function negamax(depth, alpha, beta, chessboard, color)
    if depth <= 0
        return evaluate_board(chessboard) * color
    end
    bestscore = -1e8
    score = -1e8
    leg = moves(chessboard)

    for move in leg
        u = domove!(chessboard, move)
        score = -negamax(depth - 1, -beta, -alpha, chessboard, -color)
        undomove!(chessboard, u)
        if score > bestscore
            bestscore = score
            if score > alpha
                if score >= beta
                    return score
                end
                alpha = score
            end
        end
    end
    return alpha
end
