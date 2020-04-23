using Chess, Chess.Book
using Memoize
include("eval.jl")

stop = false::Bool
calculating = true::Bool
begin_time = 0::Int

killers = 0::Int


nullcut = 0::Int
timecontrol = false
playtime = 0::Int
# pv_move = nothing

function repetition(chessboard, pv::Pv)::Bool
    if chessboard.r50 == 0
        return false
    end
    if chessboard.key in (length(pv.repetition) > 3 ? pv.repetition[1:3] : pv.repetition)
        return true
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
    score =  evaluate_board(chessboard::Board) * color::Int
    MATE = 100000::Int
    DRAW = 0::Int

   #=  if ischeckmate(chessboard)

        print("CHECKMATE")
        score =  1e5
    end
    if isstalemate(chessboard)
        score = -1e5

    end =#
    #pos = generate_pos_key(chessboard, key)
    key.nodes += 1::Int
    if repetition(chessboard, pv) && ply > 0
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
                #=  if ischeckmate(chessboard)
                    print("CHECKMATE MOVE")
                    score = 1e5
                end
                if isstalemate(chessboard)
                    score = -1e5

                end =#

            u = domove!(chessboard, all_moves[i][1])
            ply += 1
            score = -quiescence(-beta, -alpha, chessboard, -color, maxdepth - 1, key, pv, ply, posKey)
            undomove!(chessboard, u)
            ply -= 1

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
        # return evaluate_board(chessboard) * color
        return quiescence(alpha, beta, chessboard, color, 1, key, pv, ply, posKey)
    end

    key.nodes += 1::Int

    if (key.nodes & 2047) == 0
        time_control()
    end
    #pos = generate_pos_key(chessboard, key)
     if repetition(chessboard, pv) && ply > 0
        return DRAW
    end 
    if ischeck(chessboard)
        depth += 1
    end
    score = -100000000
    pv_move = MOVE_NULL::Move
    hashbool,  hashscore::Int, pv_move::Move = probe_hash_entry(chessboard, score, alpha, beta, depth, pv, key)
    if hashbool
        # global hashcut += 1::Int
        return hashscore
    end

    if nullmove && !ischeck(chessboard) && ply > 0 && big_piece(chessboard) && depth >= 4
        u = donullmove!(chessboard)

        ply += 1::Int
        score = -negamax(depth - 4, -beta, -beta + 1, chessboard, -color, false, ply, pv, key, posKey)
        undomove!(chessboard, u)

        ply -= 1::Int
        if calculating == false && timecontrol == true
            return 0
        end
        if score >= beta && score < MATE
            # global nullcut += 1::Int
            return beta
        end
    end
    bestmove = MOVE_NULL::Move
    oldaplha = alpha
    bestscore = -100000000
    bm = Tuple
    leg = generate_moves(chessboard, pv)
    if pv_move != MOVE_NULL

        @inbounds for i in 1:1:length(leg)
            if leg[i][1] == pv_move
                # global pvmovecut += 1::Int

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

    @inbounds for i in 1:1:length(leg)
        pick_next_move(i, leg)
        # global checkmate = false
        if calculating == false && timecontrol == true
            break
        end

        u = domove!(chessboard, leg[i][1])


        ply += 1::Int
        score = -negamax(depth - 1, -beta, -alpha, chessboard, -color, true, ply, pv, key, posKey)


        undomove!(chessboard, u)
        ply -= 1::Int

        if score > bestscore
            bestscore = score
            bestmove = leg[i][1]
            bm = leg[i]
            if score > alpha
                if score >= beta

                    if leg[i][2] == 0
                       # global killers += 1::Int
                        pv.killer_moves[2] = pv.killer_moves[1]
                        pv.killer_moves[1] = leg[i]

                    end
                    store_Pv_Move(chessboard, bestmove, beta, "HFBETA", depth, key, pv)
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
        store_Pv_Move(chessboard, bestmove, bestscore, "HEXACT", depth, key, pv)
    else
        store_Pv_Move(chessboard, bestmove, alpha, "HALPHA", depth, key, pv)
    end
    return alpha
end

function calc_best_move(chessboard, depth, pv, key, posKey)::Move
    global calculating = true
    bookmove = nothing

    bookmove = pickbookmove(chessboard, "/home/manuel/Dokumente/juliachess/openings/top19.obk")
    if bookmove !== nothing
        push!(pv.repetition, chessboard.key)
        return bookmove
    end
    clearPvTable(pv)
    clear_search(pv)
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
        # global nullcut = 0
        key.nodes = 0
        # global nullcut = 0
        global begin_time = time_ns()
        # global hashcut = 0
        # global killers = 0
        current_depth += 1
        value =  negamax(current_depth, -100000000, 100000000, chessboard, side == WHITE ? 1 : -1, true, 0, pv, key, posKey)
        if calculating == false
            break
        end
        best_move = probe_Pv_Table(chessboard, key, pv)
        get_history(current_depth, chessboard, key, pv)
        pv_search = [pv.history[i] for i in 1:1:current_depth]

        print("info score cp ", value, " currmove: ", movetosan(chessboard, best_move), " depth ", current_depth, " nodes ", key.nodes,  " time ", (time_ns() - begin_time) * 0.000000001, " pv ")
        @inbounds for i in 1:1:current_depth
            if pv_search[i] != MOVE_NULL

                print(tostring(pv_search[i]), " ")
            else
                break
            end
        end
        print("\n")
        # println(" nullcuts ", nullcut, " hashcut ", hashcut, " hashtablehit ", hashtablehit, " overrides ", over_write, " new writes ", new_write, " killers ", killers, " pvmovecut ", pvmovecut) =#
    end
    pushfirst!(pv.repetition, chessboard.key)
    println(pv.repetition)
    return best_move
end
