using Chess, Chess.Book
using Memoize
include("eval.jl")
debug = false
stop = false::Bool
calculating = true::Bool
begin_time = 0::Int

killers = 0::Int

new_write = 0 ::Int
over_write = 0 ::Int
pvmovecut = 0 ::Int
nullcut = 0::Int
timecontrol = false
playtime = 0::Int
hashtablehit = 0
# pv_move = nothing

function repetition(chessboard, pv::Pv, ply)::Bool
    index = (pv.ply - chessboard.r50)
    if index <= 0 
        index = 1
    end
    index_rep = 1
    same_keys = 0
    #println(pv.repetition)
        for i = index:1:pv.ply-1
            if chessboard.key == pv.repetition[i]
                return true
            end
        end
    
    return false
end

function time_control()

    if ((time_ns() - begin_time) * 0.000001) > playtime && timecontrol == true
        println("TIMES UP")
        global calculating = false
    end
end

function pick_next_move(move_num::Int, movelist)
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

function quiescence(alpha::Int, beta::Int, chessboard::Board, color::Int, maxdepth::Int, key::Keys, pv::Pv, ply::Int, posKey)::Int
    all_moves = only_capture_moves(chessboard::Board, pv)::Array{Tuple,1}
    score =  evaluate_board(chessboard::Board, pv) * color::Int
    MATE = 100000::Int
    DRAW = 0::Int
    if length(all_moves) == 0
        if ischeck(chessboard)
            return -MATE 
        else
            return DRAW
        end
    end
    key.nodes += 1::Int
    if pv.ply > 4 && repetition(chessboard, pv, pv.ply) 
        return DRAW
    end 
    if (key.nodes & 2047) == 0
        time_control()
    end
    if score >= beta
        return beta
    end
    if score > alpha
        alpha = score
    end
    if maxdepth >= 0
        for i in 2:1:length(all_moves)
            all_moves = pick_next_move(i, all_moves)
            if calculating == false
                break
            end
            u = domove!(chessboard, all_moves[i][1])
            pv.ply += 1
            pv.repetition[pv.ply] = chessboard.key
            score = -quiescence(-beta, -alpha, chessboard, -color, maxdepth - 1, key, pv, pv.ply, posKey)
            undomove!(chessboard, u)
            pv.ply -= 1

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

function negamax(depth, alpha::Int, beta::Int, chessboard, color, nullmove, ply, pv, key, posKey)::Int
    MATE = 100000::Int
    DRAW = 0::Int
    if depth <= 0
        #return evaluate_board(chessboard, pv) * color
        return quiescence(alpha, beta, chessboard, color, 1, key, pv, pv.ply, posKey)
    end

    key.nodes += 1::Int
    if (key.nodes & 2047) == 0
        time_control()
    end
    #pos = generate_pos_key(chessboard, key)
     if pv.ply > 2 && repetition(chessboard, pv, pv.ply)
        return DRAW
    end 
    score = -100000000
    bestmove = MOVE_NULL::Move
    pv_move = MOVE_NULL::Move
    hashbool,  hashscore::Int, pv_move::Move = probe_hash_entry(chessboard, score, alpha, beta, depth, pv, key)
    if hashbool
        if debug
            global hashcut += 1::Int
        end
        return hashscore
    end
    #nullmove pruning
    if nullmove && !ischeck(chessboard) && pv.ply > 0 && big_piece(chessboard) && depth >= 4
        u = donullmove!(chessboard)
        pv.ply += 1::Int
        score = -negamax(depth - 4, -beta, -beta + 1, chessboard, -color, false, pv.ply, pv, key, posKey)
        undomove!(chessboard, u)

        pv.ply -= 1::Int
        if calculating == false && timecontrol == true
            return 0
        end
        if score >= beta && score < MATE
            if debug
                global nullcut += 1::Int
            end
            
            return beta
        end
    end
    
    oldaplha = alpha
    bestscore = -100000000
    bm = Tuple
    leg = generate_moves(chessboard, pv)
    if pv_move != MOVE_NULL
        @inbounds for i in 1:1:length(leg)
            if leg[i][1] == pv_move
                if debug
                    global pvmovecut += 1::Int
                end 
                leg[i] = (leg[i][1], 2000000)
                break
            end
        end
    end

    @inbounds for i in 1:1:length(leg)
        pick_next_move(i, leg)
        # global checkmate = false
        if calculating == false && timecontrol == true
            break
        end

        u = domove!(chessboard, leg[i][1])
        pv.ply += 1::Int
        pv.repetition[pv.ply] = chessboard.key
        score = -negamax(depth - 1, -beta, -alpha, chessboard, -color, true, pv.ply, pv, key, posKey)
        undomove!(chessboard, u)
        pv.ply -= 1::Int

        if score > bestscore
            bestscore = score
            bestmove = leg[i][1]
            bm = leg[i]
            if score > alpha
                if score >= beta
                    if leg[i][2] == 0
                        if debug
                            global killers += 1::Int
                        end
                        pv.killer_moves[2] = pv.killer_moves[1]
                        pv.killer_moves[1] = leg[i]
                        pv.killer_moves[3] = pv.ply
                    end
                    store_Pv_Move(chessboard, bestmove, beta, "HFBETA", depth, key, pv)
                    return score
                end
                if leg[i][2] == 0
                    pv.searchHistory[from(bestmove).val, to(bestmove).val] += depth
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
        store_Pv_Move(chessboard, bestmove, bestscore, "HEXACT", depth, key, pv)
    else
        store_Pv_Move(chessboard, bestmove, alpha, "HALPHA", depth, key, pv)
    end
    return alpha
end



function calc_best_move(chessboard, depth, pv, key, posKey)::Move
    global calculating = true
    bookmove = nothing

    bookmove = pickbookmove(chessboard, "C:\\Users\\manue\\Documents\\juliachessengine\\openings\\top19.obk")
    if bookmove !== nothing
        return bookmove
    end
    clearPvTable(pv)
    clear_search(pv)
    clear_rep(pv)
    side = sidetomove(chessboard)
    if timecontrol == true
        global playtime = side == WHITE ? white_time / 30 : black_time / 30
    else
        global playtime = 0
    end
    current_depth = 0
    max_death = depth
    prev_move = nothing
    best_move = nothing
    number_of_pieces = count_pieces(chessboard)
    while current_depth < max_death
        global begin_time = time_ns()
        key.nodes = 0
        if debug
            global nullcut = 0
            global hashcut = 0
            global killers = 0
            global over_write = 0
            global new_write = 0
            global hashtablehit = 0
            global nullcut = 0
        end
        current_depth += 1
        pv.ply = 0
        value =  negamax(current_depth, -100000000, 100000000, chessboard, side == WHITE ? 1 : -1, true, 0, pv, key, posKey)
        if calculating == false
            break
        end
        best_move = probe_Pv_Table(chessboard, key, pv)
        #get_history(current_depth, chessboard, key, pv)
        #pv_search = [pv.history[i] for i in 1:1:current_depth]

        print("info score cp ", value, " currmove: ", movetosan(chessboard, best_move), " depth ", current_depth, " nodes ", key.nodes,  " time ", (time_ns() - begin_time) * 0.000000001, " pv ")
        #= @inbounds for i in 1:1:current_depth
            if pv_search[i] != MOVE_NULL

                print(tostring(pv_search[i]), " ")
            else
                break
            end
        end =#
        print("\n")
        if debug
            println("\nDEBUG [nullcut : ", nullcut, ", hashcut : ", hashcut, ", killers : ", killers, ", new_write : ", new_write , ", over_write : ", over_write , ", hashtablehit : ",  hashtablehit," pvmovecut : ", pvmovecut, "]")
        end
        # println(" nullcuts ", nullcut, " hashcut ", hashcut, " hashtablehit ", hashtablehit, " overrides ", over_write, " new writes ", new_write, " killers ", killers, " pvmovecut ", pvmovecut) =#
    end
    return best_move
end
