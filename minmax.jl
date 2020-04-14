using Chess, Chess.Book
include("eval.jl")
stop = false
checkmate = false
stalemate = false
calculating = true
begin_time = 0
nodes = 0
killers = 0
history = []
killer_moves = [(MOVE_NULL, 0), (MOVE_NULL, 0)]
nullcut = 0
ply = 0
pvmovecut = 0
leg = MoveList(200)
# pv_move = nothing
function time_control()

    if ((time_ns() - begin_time) * 1e-6) > playtime && timecontrol == true
        println("TIMES UP")
        global calculating = false
    end
end

function pick_next_move(move_num, movelist)
    temp = MOVE_NULL
    best_score = 0
    index = 1
    for i in move_num:1:length(movelist)
        if movelist[i][2] > best_score
            best_score = movelist[i][2]
            index = i
        end
    end

    temp = movelist[move_num]
    movelist[move_num] = movelist[index]
    movelist[index] = temp
    return movelist
end

function quiescence(alpha, beta, chessboard, color, maxdepth)
    all_moves = only_capture_moves(chessboard)
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
    if maxdepth >= 0
        for i in 1:1:length(all_moves)
            all_moves = pick_next_move(i, all_moves)
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
  
            u = domove!(chessboard, all_moves[i][1])
            global ply += 1
            score = -quiescence(-beta, -alpha, chessboard, -color, maxdepth - 1)
            undomove!(chessboard, u)
  
            global ply -= 1
            if score > alpha
                bestmove = all_moves[i][1]
                if score >= beta

                   
                    return score
                end
                    
                alpha = score

            end
        end
        return alpha
    end
    return alpha
end
#= 
fen = r1bqkb1r/ppp3pp/2np1p2/8/3QP3/2N1B3/PPP2PPP/R3KB1R w KQkq - 4 9
without null move :
info score cp 60 currmove: Bb5 depth 1 nodes 34 time 0.330648871 pv f1b5 
info score cp 40 currmove: Bb5 depth 2 nodes 97 time 0.10537494700000001 pv f1b5 d6d5 
info score cp 90 currmove: Qa4 depth 3 nodes 1121 time 0.06933438700000001 pv d4a4 c8e6 e3a7 
info score cp 30 currmove: Qd2 depth 4 nodes 9572 time 0.659721122 pv d4d2 c8e6 c3d5 f6f5 
info score cp 85 currmove: Bb5 depth 5 nodes 71685 time 4.371753688 pv f1b5 a7a6 b5a4 c8d7 a4c6 
info score cp 40 currmove: Qd5 depth 6 nodes 473477 time 29.81124695 pv d4d5 f8e7 d5h5 g7g6 h5d5 c6e5

with nullmove:
info score cp 60 currmove: Bb5 depth 1 nodes 34 nullcuts 0 time 0.159650294 pv f1b5 
info score cp 40 currmove: Bb5 depth 2 nodes 97 nullcuts 0 time 0.061241910000000004 pv f1b5 d6d5 
info score cp 90 currmove: Qa4 depth 3 nodes 1121 nullcuts 0 time 0.047682023000000004 pv d4a4 c8e6 e3a7 
info score cp 30 currmove: Qd2 depth 4 nodes 9572 nullcuts 0 time 0.594707647 pv d4d2 c8e6 c3d5 f6f5 
info score cp 85 currmove: Bb5 depth 5 nodes 33331 nullcuts 39 time 1.3627204030000002 pv f1b5 a7a6 b5a4 c8d7 a4c6 
info score cp 40 currmove: Qd5 depth 6 nodes 297611 nullcuts 204 time 11.563456054000001 pv d4d5 a7a6 b5a4 c8d7 a4c6

with hashtable:
info score cp 60 currmove: Bb5 depth 1 nodes 34 time 0.206197186 pv f1b5 
 nullcuts 0 hashcut 0 hashtablehit 0
info score cp 40 currmove: Bb5 depth 2 nodes 81 time 0.07721535800000001 pv f1b5 d6d5 
 nullcuts 0 hashcut 1 hashtablehit 2
info score cp 90 currmove: Qa4 depth 3 nodes 1068 time 0.056935206 pv d4a4 c8e6 e3a7 
 nullcuts 0 hashcut 2 hashtablehit 4
info score cp 30 currmove: Qd2 depth 4 nodes 8615 time 0.37144631 pv d4d2 c8e6 c3d5 f6f5 
 nullcuts 0 hashcut 151 hashtablehit 181
info score cp 85 currmove: Bb5 depth 5 nodes 29261 time 1.227512694 pv f1b5 a7a6 b5a4 c8d7 a4c6 
 nullcuts 39 hashcut 355 hashtablehit 499
info score cp 40 currmove: Qd5 depth 6 nodes 229035 time 9.122102363 pv d4d5 f8e7 d5h5 g7g6 a4c6 
 nullcuts 177 hashcut 3849 hashtablehit 5313 =#
function negamax(depth, alpha, beta, chessboard, color, nullmove)
    if depth <= 0
        # return evaluate_board(chessboard) * color
        return quiescence(alpha, beta, chessboard, color, 1)
    end
    
    global nodes += 1
    
    if (nodes & 2047) == 0
        time_control()
    end
   
        
    if ischeck(chessboard)
        depth += 1
    end
    score = -1e8
    pv_move = nothing
    hashbool,  hashscore, pv_move = probe_hash_entry(chessboard, score, alpha, beta, depth)
    if hashbool
        global hashcut += 1
        return hashscore
    end
    
    if nullmove && !ischeck(chessboard) && ply > 0 && big_piece(chessboard) && depth >= 4
        u = 0

        u = donullmove!(chessboard)
  
        global ply += 1
        score = -negamax(depth - 4, -beta, -beta + 1, chessboard, -color, false)
        undomove!(chessboard, u)
        
        global ply -= 1
        if calculating == false && timecontrol == true
            return 0
        end
        if score >= beta && score < MATE
            global nullcut += 1
            return beta
        end
    end
    bestmove = nothing
    oldaplha = alpha
    bestscore = -1e8
    leg = generate_moves(chessboard)
    if pv_move !== nothing && pv_move != MOVE_NULL
        global pvmovecut += 1
        for i in 1:1:length(leg)
            if leg[i][1] == pv_move 
                global killers += 1
                leg[i] = (leg[i][1], 2000000)
                break
            end
        end
    end 

    

   #=  if depth <= 2
        if length(leg) > 20
            leg = leg[1:20]
        end
    end =#
   
    for i in 1:1:length(leg)
        pick_next_move(i, leg)
        u = 0
        global checkmate = false
        if calculating == false && timecontrol == true
            break
        end
  
        u = domove!(chessboard, leg[i][1])


        global ply += 1
        score = -negamax(depth - 1, -beta, -alpha, chessboard, -color, true)
        undomove!(chessboard, u)
        global ply -= 1
        
        if score > bestscore
            bestscore = score
            bestmove = leg[i][1]
            if score > alpha       
                if score >= beta
                    
                    if leg[i][2] == 0
                        
                        global killer_moves[2] = killer_moves[1]
                        global killer_moves[1] = leg[i]
                        
                    end
                    store_Pv_Move(chessboard, bestmove, beta, "HFBETA", depth)
                    return score
                end     
                alpha = score
            end
        end
        
        
    end

    if length(leg) == 0
        if ischeck(chessboard)
            return -MATE
        else
            return DRAW
        end
    end

    if alpha != oldaplha
        store_Pv_Move(chessboard, bestmove, bestscore, "HEXACT", depth)
    else
        store_Pv_Move(chessboard, bestmove, alpha, "HALPHA", depth)
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
    global playtime = side == WHITE ? white_time / 30 : black_time / 30
    current_depth = 0
    max_death = depth
    prev_move = nothing
    best_move = nothing
    number_of_pieces = count_pieces(chessboard)
    if endgame == true
        max_death += 1
    end
    while current_depth < max_death
        # global nullcut = 0
        global nodes = 0
        global nullcut = 0
        global begin_time = time_ns()
        global hashcut = 0
        global killers = 0
        current_depth += 1
        value = negamax(current_depth, -1e8, 1e8, chessboard, side == WHITE ? 1 : -1, true)
        if calculating == false
            break
        end
        best_move = probe_Pv_Table(chessboard)
        get_history(current_depth, chessboard)
        pv = [search_history[i] for i in 1:1:current_depth]

        print("info score cp ", value, " currmove: ", movetosan(chessboard, best_move), " depth ", current_depth, " nodes ", nodes,  " time ", (time_ns() - begin_time) * 1e-9, " pv ")
      
        for i in 1:1:current_depth
            if pv[i] != MOVE_NULL
                
                print(tostring(pv[i]), " ")
            else 
                break
            end
        end
        print("\n")
        println(" nullcuts ", nullcut, " hashcut ", hashcut, " hashtablehit ", hashtablehit, " overrides ", over_write, " new writes ", new_write, " killers ", killers, " pvmovecut ", pvmovecut)
  
        
    end
    push!(history, generate_pos_key(chessboard))
    return best_move
end


