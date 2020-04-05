using Chess, Chess.Book
include("eval.jl")
stop = false
checkmate = false
stalemate = false
nodes = 0
function quiescence(alpha, beta, chessboard, color, maxdepth)
    all_moves = capture_moves(chessboard)
    score = evaluate_board(chessboard) * color
   #=  if ischeckmate(chessboard)

        print("CHECKMATE")
        score =  1e5
    end
    if isstalemate(chessboard)
        score = -1e5

    end =#
    global nodes += 1
    if score >= beta
        return score
    end
    if score > alpha
        alpha = score
    end
    if !isempty(all_moves) && maxdepth >= 0
        if length(all_moves) > 20
            all_moves = all_moves[1:20]
        end
        for move in all_moves
           #=  if ischeckmate(chessboard)
                print("CHECKMATE MOVE")
                score = 1e5
            end
            if isstalemate(chessboard)
                score = -1e5
        
            end =#
            
            u = domove!(chessboard, move)
            score = -quiescence(-beta, -alpha, chessboard, -color, maxdepth - 1)
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
    return score
end
# function that goes through all moves and picks the best one with minmax algorithm
function calc_best_move(chessboard, depth)

    bookmove = nothing

    bookmove = pickbookmove(chessboard, "/home/manuel/Dokumente/juliachess/openings/carlsennaka.obk", minscore = 0.01, mingamecount = 20)
    if bookmove !== nothing
        return bookmove
    end
    side = sidetomove(chessboard)
    current_depth = 0
    max_death = depth
    best_move = nothing
    while current_depth < max_death
        global nodes = 0
        begin_time = time_ns()
        best_value = -1e8 
	
        current_depth += 1
        all_moves = sort_moves(chessboard)
        if depth >= 4
            if length(all_moves) > 20
                all_moves = all_moves[1:20]
            end
        end
        for move in all_moves
            global checkmate = false
            global nodes += 1
            u = domove!(chessboard, move)
            value = -negamax(current_depth, -1e8, 1e8, chessboard, side == WHITE ? -1 : 1)
            if checkmate == true
                if value > 0
                    println("CHECKMATE")
                    undomove!(chessboard, u)
                    return move
                end
            end
            undomove!(chessboard, u)
            if (value > best_value)
                best_value = value
                best_move = move
            
      	     end
       	end
        # println("info score cp ", best_value, " bestmove: ", movetosan(chessboard, best_move), " depth ", current_depth, " nodes ", nodes, " time ", (time_ns() - begin_time) * 1e-9, " nodes/second: ", nodes / ((time_ns() - begin_time) * 1e-9))
    end
    return best_move
end

function negamax(depth, alpha, beta, chessboard, color)
    if depth <= 0
        # return evaluate_board(chessboard) * color
        return quiescence(alpha, beta, chessboard, color, 1)
    end
    global nodes += 1
    bestscore = -1e8
    score = -1e8
    leg = sort_moves(chessboard)
    if depth <= 2
        if length(leg) > 30
            leg = leg[1:30]
        end
    end
    if ischeckmate(chessboard)
        global checkmate = true
    end
        
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
