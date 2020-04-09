using Chess, Chess.Book
include("eval.jl")
stop = false
checkmate = false
stalemate = false
calculating = true
begin_time = 0
nodes = 0
history = []


function time_control()

    if ((time_ns() - begin_time) * 1e-6) > playtime && timecontrol == true
        println("TIMES UP")
        global calculating = false
    end
end

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

    if (nodes & 2047) == 0
        time_control()
    end
    if score >= beta
        return beta
    end
    if score > alpha
        alpha = score
    end

    for move in all_moves
        if calculating == false
            break
        end
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
        if score > alpha
            bestmove = move 
            if score >= beta
                return beta
            end
                
            alpha = score

        end
    end
    return alpha
end

function negamax(depth, alpha, beta, chessboard, color)
    if depth <= 0
        # return evaluate_board(chessboard) * color
        return quiescence(alpha, beta, chessboard, color, 1)
    end
    
    global nodes += 1

    if (nodes & 2047) == 0
        time_control()
    end
    if ischeckmate(chessboard)
        return -MATE
    end
    if isdraw(chessboard)
        return  DRAW
    end
        
    if ischeck(chessboard)
        depth += 1
    end
    bestmove = nothing
    oldaplha = alpha
    bestscore = -1e8
    score = -1e8
    leg = sort_moves(chessboard)
    if endgame == false
        if depth <= 2
            if length(leg) > 20
                leg = leg[1:20]
            end
        end
    end 
   
    for move in leg
        global checkmate = false
        if calculating == false && timecontrol == true
            println("BREAK")
            break
        end
        u = domove!(chessboard, move)
        score = -negamax(depth - 1, -beta, -alpha, chessboard, -color)

        undomove!(chessboard, u)

        if score > alpha       
            bestmove = move 
            
            if score >= beta
                # store_Pv_Move(chessboard, bestmove)
                return beta
            end     
            alpha = score
        end
        
        
    end
    
    if length(leg) == 0
        if ischeck(chessboard)
            return -MATE + depth
        else
            return DRAW
        end
    end
    if alpha != oldaplha
        store_Pv_Move(chessboard, bestmove)

    end
    return alpha
end

# function that goes through all moves and picks the best one with minmax algorithm
function calc_best_move(chessboard, depth)
    global calculating = true
    bookmove = nothing

    bookmove = pickbookmove(chessboard, "/home/manuel/Dokumente/juliachess/openings/top19.obk")
    if bookmove !== nothing
        return bookmove
    end
    clearPvTable()
    clear_search()
    side = sidetomove(chessboard)
    global playtime = side == WHITE ? white_time / 40 : black_time / 40
    current_depth = 0
    max_death = depth
    prev_move = nothing
    best_move = nothing
    number_of_pieces = count_pieces(chessboard)
    if number_of_pieces < 10
        global endgame = true
    end
    if endgame == true
        max_death += 1
    end
    while current_depth < max_death
        
        global nodes = 0
        global begin_time = time_ns()

	
        current_depth += 1
        

        value = negamax(current_depth, -1e8, 1e8, chessboard, side == WHITE ? 1 : -1)
        if calculating == false
            break
        end
        best_move = probe_Pv_Table(chessboard)
        get_history(current_depth, chessboard)
        pv = [search_history[i] for i in 1:1:current_depth]
        println("info score cp ", value, " currmove: ", movetosan(chessboard, best_move), " depth ", current_depth, " nodes ", nodes, " time ", (time_ns() - begin_time) * 1e-9, " pv ", pv)
    
  
        
    end
    push!(history, generate_pos_key(chessboard))
    return best_move
end


