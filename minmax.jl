using Chess, Chess.Book
using Base.Threads: @spawn, threadid, SpinLock

include("eval.jl")
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
    index1 = (pv.hisPly[threadid()] - chessboard.r50) ::Int
    
    if index1 < 0
        return false
    end
    @inbounds for i = 0:1:(pv.hisPly[threadid()] - 2)
        if chessboard.key == pv.repetition[i + 1, threadid()]
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
        global timeover = true
    end
end

function Base.setindex!(list::MoveList, m::Move, i::Int)
    list.moves[i] = m
end


function pick_next_move_fast(chessboard::Board, move_num::Int, pv::Pv, m::MoveList, pvmove::Move, quiescenceBool)::MoveList

    
    temp = MOVE_NULL
    best_score = Int64(0)
    value = Int64(0)
    index = 1
    #m = moves(chessboard)
    @inbounds for i in move_num:1:m.count
        moveto = pieceon(chessboard, to(m[i]))
        value = Int64(0)
        if !quiescenceBool
            if m[i] in pv.inSearch
                continue
            end
            if pvmove != MOVE_NULL && pvmove == m[i]
                if pv.debug
                    global pvmovecut += 1
                end 
                value = 2000000
                index = i
                break
            elseif cancastlekingside(chessboard, WHITE) && to(m[i]) == SQ_G1 && pieceon(chessboard, from(m[i])) == PIECE_WK
                value = 1000000
            elseif cancastlekingside(chessboard, BLACK) && to(m[i]) == SQ_G8 && pieceon(chessboard, from(m[i])) == PIECE_BK
                value = 1000000
            elseif pv.killer_moves[1, pv.ply[threadid()]] == m[i]
                #println("KILLER1: ", pv.killer_moves[1, pv.ply])
                value =  900000
            elseif pv.killer_moves[2, pv.ply[threadid()]] == m[i]
                #println("KILLER2: ", pv.killer_moves[2])
                value =  800000
            elseif moveto != EMPTY
                value = 1000000 + pv.mvvlva_scores[ptype(moveto).val, ptype(pieceon(chessboard, from(m[i]))).val]
                #println("$(pieceon(chessboard, from(m[i]))) x $(moveto) : $(pv.mvvlva_scores[ptype(moveto).val, ptype(pieceon(chessboard, from(m[i]))).val])")
                #println("$(m[i])")
            elseif epsquare(chessboard) != SQ_NONE
                value = 1000000 + 105
            else
                value = pv.searchHistory[from(m[i]).val, to(m[i]).val]
            end
        else
            if moveto != EMPTY
                value = 1000000 + pv.mvvlva_scores[ptype(moveto).val, ptype(pieceon(chessboard, from(m[i]))).val]
                #println("$(pieceon(chessboard, from(m[i]))) x $(moveto) : $(pv.mvvlva_scores[ptype(moveto).val, ptype(pieceon(chessboard, from(m[i]))).val])")
                #println("$(m[i])")
            elseif epsquare(chessboard) != SQ_NONE
                value = 1000000 + 105 
            end
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

function strudlmove!(chessboard, move, pv)
    u = domove!(chessboard, move)
    pv.repetition[pv.hisPly[threadid()] + 1, threadid()] = chessboard.key
    pv.hisPly[threadid()] += 1
    pv.ply[threadid()] += 1
    return u
end

function undostrudlmove!(chessboard, undoinfo, pv)
    pv.repetition[pv.hisPly[threadid()] + 1, threadid()] = 0
    pv.hisPly[threadid()] -= 1
    pv.ply[threadid()] -= 1
    undomove!(chessboard, undoinfo)
end

function quiescence(alpha::Int, beta::Int, chessboard::Board, color::Int, key::Keys, pv::Pv, lists)::Int
    DRAW = 0::Int
    if (key.nodes[threadid()] & 2047) == 0
        time_control()
    end
    key.nodes[threadid()] += 1::Int
    if (ismaterialdraw(chessboard) || repetition(chessboard, pv, pv.ply[threadid()]) || chessboard.r50 >= 100)
        return DRAW
    end 
     if pv.ply[threadid()] > 20
        return evaluate_board(chessboard, pv)::Int
    end 
    score = evaluate_board(chessboard::Board, pv)::Int
   
    if score >= beta
        return beta
    end
    if score > alpha
        alpha = score
    end
    movelist = lists[pv.ply[threadid()]]
    recycle!(movelist) 
    all_moves = moves(chessboard, movelist)
    bestmove = MOVE_NULL
    score = -pv.INF
    oldaplha = alpha
    for i in 1:1:all_moves.count
        on = pieceon(chessboard, to(all_moves[i]))
        if on == EMPTY  # only captures
            continue
        end
        pick_next_move_fast(chessboard, i, pv, all_moves, MOVE_NULL, true)
        u = strudlmove!(chessboard, all_moves[i], pv)
        score = -quiescence(-beta, -alpha, chessboard, -color, key, pv, lists)
        undostrudlmove!(chessboard, u, pv)
        if calculating == false
            return 0
        end
        if score > alpha
            if score >= beta
                return beta
            end
            alpha = score
            bestmove = all_moves[i]
        end
    end
    return alpha
end


t1 = nothing
t2 = nothing
t3 = nothing
t4 = nothing

function copyBoard(board::Board)
    b = Board(board.board, board.bycolor, board.bytype, board.side, board.castlerights, board.castlefiles, board.epsq, board.r50, board.ksq, board.move, board.occ, board.checkers, board.pin, board.key, board.is960)
    return b
end

function negamax(depth, initalDepth,alpha::Int, beta::Int, chessboard, color, nullmove, pv, key, lists, leg=nothing)::Int
    DRAW = 0::Int
    bestmove = MOVE_NULL::Move
    pv_move = MOVE_NULL::Move
    oldaplha = alpha
    bestscore = -pv.INF
    score = -pv.INF
    @assert beta > alpha
    @assert depth >= 0
    #chessboard = copyBoard(b)
    
    
    if depth <= 0
        #return evaluate_board(chessboard, pv) * color
        return quiescence(alpha, beta, chessboard, color, key, pv, lists)
    end
    
    if (key.nodes[threadid()] & 2047) == 0
        time_control()
    end 
    key.nodes[threadid()] += 1::Int

    if pv.ply[threadid()] > 1 && (ismaterialdraw(chessboard) || repetition(chessboard, pv, pv.ply[threadid()]) || chessboard.r50 >= 100) 
        return DRAW
    end 
     if pv.ply[threadid()] > 20
        return evaluate_board(chessboard, pv)::Int
    end 
    
    hashbool, hashscore::Int, pv_move::Move = probe_hash_entry(chessboard, score, alpha, beta, depth, pv, key)
    if hashbool
         if pv.debug
            global hashcut += 1::Int
        end 
        return hashscore
    end 
    check = ischeck(chessboard)
    #nullmove pruning
     if nullmove && !check && pv.ply[threadid()] > 0 && big_piece(chessboard) && depth >= 4
        u = donullmove!(chessboard)
        pv.ply[threadid()] += 1::Int
        pv.hisPly[threadid()] += 1
        score = -negamax(depth - 4, initalDepth,-beta, -beta + 1, chessboard, -color, false,  pv, key, lists)
        undostrudlmove!(chessboard, u, pv)
        if calculating == false
            return 0
        end
        if score >= beta && abs(score) < pv.INF
#=             if pv.debug
                global nullcut += 1::Int
            end =#
            
            return beta
        end
    end 
    
    if check
        depth += 1
    end
    movelist = lists[pv.ply[threadid()]]
    recycle!(movelist)
    leg = moves(chessboard, movelist)

    score = -pv.INF
    foundPv = false::Bool

    
    @inbounds for i in 1:1:leg.count
        pick_next_move_fast(chessboard, i, pv, leg, pv_move, false)
        # global checkmate = false 
        undo = strudlmove!(chessboard, leg[i], pv)
        #print(undo)
        if foundPv
            score = -negamax(depth - 1, initalDepth,-alpha - 1, -alpha, chessboard, -color, true,  pv, key, lists)
            if score > alpha && score < beta
                score = -negamax(depth - 1, initalDepth,-beta, -alpha, chessboard, -color, true,  pv, key, lists)
            end
        else  
            score = -negamax(depth - 1, initalDepth,-beta, -alpha, chessboard, -color, true,  pv, key, lists)
        end
        undostrudlmove!(chessboard, undo, pv)
        if calculating == false
            return 0
        end
     
        if score > bestscore
            bestscore = score
            bestmove = leg[i]
            if score > alpha
                moveto = pieceon(chessboard, to(leg[i]))
                if score >= beta
                    if moveto == EMPTY
                        pv.killer_moves[2, pv.ply[threadid()]] = pv.killer_moves[1, pv.ply[threadid()]]
                        pv.killer_moves[1, pv.ply[threadid()]] = leg[i]
                    end
                    store_Pv_Move(chessboard, bestmove, beta, HFBETA, depth, key, pv)
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
    
    if leg.count == 0
        if check
            return -pv.INF + pv.ply[threadid()]
        else
            return DRAW
        end
    end 

    @assert alpha >= oldaplha

    if alpha != oldaplha
        store_Pv_Move(chessboard, bestmove, bestscore, HFEXACT, depth, key, pv)
    else
        store_Pv_Move(chessboard, bestmove, alpha, HFALPHA, depth, key, pv)
    end
    return alpha
end



function calc_best_move(board, depth, pv, key, posKey)::Move
    global calculating = true
    bookmove = nothing

    bookmove = pickbookmove(board, minscore=20, mingamecount=30) #
    if bookmove !== nothing
        return bookmove
    end
    clear_search(pv)
    side = sidetomove(board)
    pv.side = side
    if timecontrol == true
        if length(pv.repetition) < 40
            global playtime = side == WHITE ? white_time / 30 : black_time / 30
        elseif length(pv.repetition) >= 40 && length(pv.repetition) <= 60
            global playtime = side == WHITE ? white_time / 10 : black_time / 10
        else 
            global playtime = side == WHITE ? white_time / 30 : black_time / 30
        end
    else
        global playtime = 0
    end
    max_death = depth
    prev_move = nothing
    best_move = MOVE_NULL
    number_of_pieces = count_pieces(board)
    lists1 = Array{MoveList, 1}(undef, 1)
    lists2 = Array{MoveList, 1}(undef, 1)
    lists3 = Array{MoveList, 1}(undef, 1)
    lists4 = Array{MoveList, 1}(undef, 1)
    for i in 1:1:4
        key.nodes[i] = 0
    end
    
    for i ∈ 1:(40)
        if i == 1
            lists1[1] = MoveList(200)
            lists2[1] = MoveList(200)
            lists3[1] = MoveList(200)
            lists4[1] = MoveList(200)
        else
            push!(lists1, MoveList(200))
            push!(lists2, MoveList(200))
            
            push!(lists3, MoveList(200))
            push!(lists4, MoveList(200))
            
        end
    end
    
    @inbounds for current_depth in 1:1:max_death - 1
        global calculating = true
        chessboard = fromfen(fen(board))
        
        global begin_time = round(Int64, time() * 1000)
       
        if pv.debug
            global hashcut = 0
            global killers = 0
            global over_write = 0
            global new_write = 0
            global hashtablehit = 0
            global pvmovecut = 0 ::Int
            global nullcut = 0
        end
       # global hashcut = 0
        
        b1 = fromfen(fen(chessboard))
        b2 = fromfen(fen(chessboard))
        b3 = fromfen(fen(chessboard))
        b4 = fromfen(fen(chessboard))
        global timeover = false
        if Threads.nthreads() == 4 && current_depth > 3
            
            t2 = @spawn negamax(current_depth, current_depth,-pv.INF , pv.INF, b2, side == WHITE ? 1 : -1, true, pv, key, lists2)
            t3 = @spawn negamax(current_depth, current_depth,-pv.INF , pv.INF, b3, side == WHITE ? 1 : -1, true, pv, key, lists3)
            t4 = @spawn negamax(current_depth, current_depth,-pv.INF , pv.INF, b4, side == WHITE ? 1 : -1, true, pv, key, lists4)
            t1 = @spawn negamax(current_depth, current_depth,-pv.INF , pv.INF, b1, side == WHITE ? 1 : -1, true, pv, key, lists1)
            t1_score = fetch(t1)
            t2_score = fetch(t2)
            t3_score = fetch(t3)
            t4_score = fetch(t4)
        elseif Threads.nthreads() == 2 && current_depth > 3
            t1 = @spawn negamax(current_depth, current_depth,-pv.INF , pv.INF, b1, side == WHITE ? 1 : -1, true, pv, key, lists1)
            t2 = @spawn negamax(current_depth, current_depth,-pv.INF , pv.INF, b2, side == WHITE ? 1 : -1, true, pv, key, lists2)
            wait(t1)
            global calculating = false
            t1_score = fetch(t1)
            t2_score = fetch(t2)
        else
            t1 = negamax(current_depth, current_depth,-pv.INF , pv.INF, b1, side == WHITE ? 1 : -1, true, pv, key, lists1)
            t1_score = t1
        end
        
            
        value = t1_score
        if calculating == false && timeover == true
            break
        end
        best_move = probe_Pv_Table(chessboard, key, pv)
        get_history(current_depth, b2, key, pv)
        pv_search = [pv.history[i] for i in 1:1:current_depth]

        print("info score cp ", value,  " currmove ", tostring(best_move), " depth ", current_depth, " nodes ", key.nodes[1],  " time ",(round(Int64, time() *1000) - begin_time), " pv ") 
       @inbounds for i in 1:1:current_depth
            if pv_search[i] != MOVE_NULL

                print(tostring(pv_search[i]), " ")
            else
                break
            end
        end  
        print("\n")
        if current_depth >= 6 && bench
        println(" NPS ", key.nodes[1] ÷ ((round(Int64, time() *1000) - begin_time) / 1000),)
        end
        if pv.debug
            println("\npv.debug [nullcut : ", nullcut, ", hashcut : ", hashcut, ", killers : ", killers, ", new_write : ", new_write , ", over_write : ", over_write , ", hashtablehit : ",  hashtablehit," pvmovecut : ", pvmovecut, "]"
                ,"[ node1: ", key.nodes[1], " node2: ", key.nodes[2],  " node3: ", key.nodes[3], " node4: ", key.nodes[4], "]"
            )
        end
        #println(hashcut)
        # println(" nullcuts ", nullcut, " hashcut ", hashcut, " hashtablehit ", hashtablehit, " overrides ", over_write, " new writes ", new_write, " killers ", killers, " pvmovecut ", pvmovecut) =#
    end 

    return best_move
end

