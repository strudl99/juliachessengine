using Chess, Chess.Book
include("eval.jl")
stop = false
checkmate = false
stalemate = false
calculating = true

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
# without pvtable = 628446 nodes (death 6), with = 464359 nodes => 26% speed increase
# function that goes through all moves and picks the best one with minmax algorithm
function calc_best_move(chessboard, depth)
    global calculating = true
    bookmove = nothing

    bookmove = pickbookmove(chessboard, "/home/manuel/Dokumente/juliachess/openings/top19.obk")
    if bookmove !== nothing
        return bookmove
    end
    clearPvTable()
    side = sidetomove(chessboard)
    playtime = side == WHITE ? white_time / 20 : black_time / 20
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
        if calculating == false
            break
        end
        global nodes = 0
        begin_time = time_ns()
        best_value = -1e8 
	
        current_depth += 1
        all_moves = sort_moves(chessboard)
        
        for move in all_moves
            
            global checkmate = false
            if calculating == false && timecontrol == true
                best_move = prev_move
                break
            end
            if ((time_ns() - begin_time) * 1e-6) > playtime && timecontrol == true
                global calculating = false
            end
            global nodes += 1
            u = domove!(chessboard, move)
            bm = probe_Pv_Table(chessboard)
            if bm != nothing
                best_move = bm
                undomove!(chessboard, u)
                continue
            end 
            value = -negamax(current_depth, -1e8, 1e8, chessboard, side == WHITE ? -1 : 1)
            
            if checkmate == true
                value += 1000
            end
            if (value > best_value)
                best_value = value
                best_move = move
                store_Pv_Move(chessboard, move)
            end
            undomove!(chessboard, u)
        end
        prev_move = best_move
        if calculating == true 
            println("info score cp ", best_value, " bestmove: ", movetosan(chessboard, best_move), " depth ", current_depth, " nodes ", nodes, " time ", (time_ns() - begin_time) * 1e-9)
        end
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
    if endgame == false
        if depth <= 2
            if length(leg) > 10
                leg = leg[1:10]
            end
        end
    end
   
    for move in leg
        global checkmate = false
        if calculating == false && timecontrol == true
            break
        end
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
    
    if length(leg) == 0
        if ischeck(chessboard)
            return -MATE + depth
        else
            return 0
        end
    end


    return alpha
end

