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
# pv_move =

function repetition(chessboard, pv::Pv, ply)::Bool
    index = (pv.hisPly - chessboard.r50) + 1 ::Int
    if index < 0
        return false
    elseif index == 0
        index = 1
    end
    @inbounds for i = index:1:pv.hisPly-1
        if chessboard.key == pv.repetition[i]
            return true
        end 
    end
    return false
end

function time_control()

    if (round(Int64, time() *1000) - begin_time) > playtime && timecontrol == true
        println("TIMES UP")
        println(playtime)
        global calculating = false
    end
end

function Base.setindex!(list::MoveList, m::Move, i::Int)
    list.moves[i] = m
end

function pick_next_move_fast(chessboard::Board, move_num::Int, pv::Pv, m::MoveList, pvmove::Move)::MoveList
    temp = MOVE_NULL
    best_score = 0
    index = 1
    #m = moves(chessboard)
    @inbounds for i in move_num:1:length(m)
        moveto = pieceon(chessboard, to(m[i]))
        if pvmove == m[i]
            if debug
                global pvmovecut += 1::Int
            end 
            value = 2000000
            index = i
            best_score = value
            continue
        elseif pv.killer_moves[1, pv.ply] == m[i]
            #println("KILLER1: ", pv.killer_moves[1, pv.ply])
            value =  900000
        elseif pv.killer_moves[2, pv.ply] == m[i]
            #println("KILLER2: ", pv.killer_moves[2])
            value =  800000
        elseif moveto != EMPTY
            value = 1000000 + pv.mvvlva_scores[ptype(moveto).val, ptype(moveto).val + 6]
        else
            value = pv.searchHistory[from(m[i]).val, to(m[i]).val]
        end
        if value > best_score
            best_score = value
            index = i
        end
    end
    temp = m[move_num]
    m[move_num] = m[index]
    m[index] = temp

    return m
end

function quiescence(alpha::Int, beta::Int, chessboard::Board, color::Int, maxdepth::Int, key::Keys, pv::Pv, lists)::Int
    MATE = 100000::Int
    DRAW = 0::Int
    if (key.nodes & 2047) == 0
        time_control()
    end
    key.nodes += 1::Int
    if (repetition(chessboard, pv, pv.ply) || chessboard.r50 >= 100)
        return DRAW
    end 
    if pv.ply > 19
        return evaluate_board(chessboard, pv)::Int
    end
    score = evaluate_board(chessboard::Board, pv)::Int
   
    if score >= beta
        return beta
    end
    if score > alpha
        alpha = score
    end
    movelist = lists[pv.ply + 1]
    if movelist.count != 0
        recycle!(movelist)
    end 
    all_moves = moves(chessboard, movelist)
    score = -100000000
    for i in 1:1:length(all_moves)
        on = pieceon(chessboard, to(all_moves[i]))
        if on == EMPTY  # only captures
            continue
        end
        pick_next_move_fast(chessboard, i, pv, all_moves, MOVE_NULL)
        u = domove!(chessboard, all_moves[i])
        pv.ply += 1
        #pv.repetition[pv.ply] = chessboard.key
        score = -quiescence(-beta, -alpha, chessboard, -color, maxdepth - 1, key, pv, lists)
        undomove!(chessboard, u)
        pv.ply -= 1
        if calculating == false
            return 0
        end
        if score > alpha
            if score >= beta
                return beta
            end

            alpha = score

        end

    end
    return alpha
end

function negamax(depth, alpha::Int, beta::Int, board, color, nullmove, pv, key, lists)::Int

    chessboard = board
    MATE = 100000::Int
    DRAW = 0::Int
    bestmove = MOVE_NULL::Move
    pv_move = MOVE_NULL::Move
    oldaplha = alpha
    bestscore = -100000000
    score = -100000000
    @assert beta > alpha
    @assert depth >= 0
    if depth <= 0
        #return evaluate_board(chessboard, pv) * color
        return quiescence(alpha, beta, chessboard, color, 1, key, pv, lists)
    end
    
    if (key.nodes & 2047) == 0
        time_control()
    end 
    key.nodes += 1::Int

    if (repetition(chessboard, pv, pv.ply) || chessboard.r50 >= 100) && pv.ply != 0
        return DRAW
    end 
    if pv.ply > 19
        return evaluate_board(chessboard, pv)::Int
    end 
    check = ischeck(chessboard)
    if check
        depth += 1
    end
    
    hashbool,  hashscore::Int, pv_move::Move = probe_hash_entry(chessboard, score, alpha, beta, depth, pv, key)
    if hashbool
        if debug
            global hashcut += 1::Int
        end
        return hashscore
    end 
    #nullmove pruning
    if nullmove && !check && pv.ply > 0 && big_piece(chessboard) && depth >= 4
        u = donullmove!(chessboard)
        pv.ply += 1::Int
        score = -negamax(depth - 4, -beta, -beta + 1, chessboard, -color, false,  pv, key, lists)
        undomove!(chessboard, u)

        pv.ply -= 1::Int
        if calculating == false && timecontrol == true
            return 0
        end
        if score >= beta && score < (MATE - 20)
            if debug
                global nullcut += 1::Int
            end
            
            return beta
        end
    end
    movelist = lists[pv.ply + 1]
    if movelist.count != 0
        recycle!(movelist)
    end
    leg = moves(chessboard, movelist)
    score = -100000000
    foundPv = false::Bool
    @inbounds for i in 1:1:length(leg)
        pick_next_move_fast(chessboard, i, pv, leg, pv_move)
        # global checkmate = false
        moveto = pieceon(chessboard, to(leg[i]))
        u = domove!(chessboard, leg[i])
        pv.ply += 1
        if foundPv
            score = -negamax(depth - 1, -alpha - 1, -alpha, chessboard, -color, true,  pv, key, lists)
            if score > alpha && score < beta
                score = -negamax(depth - 1, -beta, -alpha, chessboard, -color, true,  pv, key, lists)
            end
        else 
       # pv.repetition[pv.ply] = chessboard.key
        score = -negamax(depth - 1, -beta, -alpha, chessboard, -color, true,  pv, key, lists)
        end
        pv.ply -= 1
        undomove!(chessboard, u)
        if calculating == false
            return 0
        end
        if score > bestscore
            bestscore = score
            bestmove = leg[i]
            if score > alpha
                if score >= beta
                    if moveto == EMPTY
                        if debug
                            global killers += 1::Int
                        end
                        pv.killer_moves[2, pv.ply] = pv.killer_moves[1, pv.ply]
                        pv.killer_moves[1, pv.ply] = leg[i]
                    end
                    store_Pv_Move(chessboard, bestmove, beta, "HFBETA", depth, key, pv)
                    return score
                end
                if moveto == EMPTY
                    pv.searchHistory[from(bestmove).val, to(bestmove).val] += depth
                end
                foundPv = true
                alpha = score
            end
        end
    end
    if length(leg) == 0
        if check
            return -MATE + pv.ply
        else
            return DRAW
        end
    end
    if alpha != oldaplha
        store_Pv_Move(chessboard, bestmove, bestscore, "HFEXACT", depth, key, pv)
    else
        store_Pv_Move(chessboard, bestmove, alpha, "HFALPHA", depth, key, pv)
    end
    return alpha
end



function calc_best_move(board, depth, pv, key, posKey)::Move
    global calculating = true
    bookmove = nothing

   #bookmove = pickbookmove(board, "/home/strudl/juliachessengine/openings/top19.obk", minscore=10) #
    if bookmove !== nothing
        return bookmove
    end
    clear_search(pv)
    side = sidetomove(board)
    pv.side = side
    if timecontrol == true
        global playtime = side == WHITE ? white_time / 30 : black_time / 30
    else
        global playtime = 0
    end
    max_death = depth
    prev_move = nothing
    best_move = nothing
    number_of_pieces = count_pieces(board)
    lists = Array{MoveList, 1}(undef, 1)
    key.nodes = 0
    pv.ply = 0
    
    @inbounds for current_depth in 1:1:max_death
        chessboard = board
        
        global begin_time = round(Int64, time() * 1000)
       
        if debug
            global hashcut = 0
            global killers = 0
            global over_write = 0
            global new_write = 0
            global hashtablehit = 0
            global pvmovecut = 0 ::Int
            global nullcut = 0
        end
       # global hashcut = 0
        for i ∈ 1:(40)
            if i == 1
                lists[i] = MoveList(200)
            else
                push!(lists, MoveList(200))
            end
        end
        value =  negamax(current_depth, -100000000, 100000000, chessboard, side == WHITE ? 1 : -1, true, pv, key, lists)
        if calculating == false
            break
        end
        best_move = probe_Pv_Table(chessboard, key, pv)
        get_history(current_depth, chessboard, key, pv)
        pv_search = [pv.history[i] for i in 1:1:current_depth]

        print("info score cp ", value,  " currmove ", tostring(best_move), " depth ", current_depth, " nodes ", key.nodes,  " time ", (round(Int64, time() *1000) - begin_time), " pv ") 
       @inbounds for i in 1:1:current_depth
            if pv_search[i] != MOVE_NULL

                print(tostring(pv_search[i]), " ")
            else
                break
            end
        end  
        print("\n")
        if debug
            println("\nDEBUG [nullcut : ", nullcut, ", hashcut : ", hashcut, ", killers : ", killers, ", new_write : ", new_write , ", over_write : ", over_write , ", hashtablehit : ",  hashtablehit," pvmovecut : ", pvmovecut, "]")
        end
        #println(hashcut)
        # println(" nullcuts ", nullcut, " hashcut ", hashcut, " hashtablehit ", hashtablehit, " overrides ", over_write, " new writes ", new_write, " killers ", killers, " pvmovecut ", pvmovecut) =#
    end 

    return best_move
end

