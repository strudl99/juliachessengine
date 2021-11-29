using Chess, Chess.Book

include("init.jl")
include("minmax.jl")
white_time = 0
black_time = 0

function check_for_and_handle_pause()
    input = split(readline())
    print(input)
end




function uciCommunication()
    ENINGENAME = "strudlsjuliachessv1.0"
    AUTHOR = "strudl"
    board = startboard()
    key,  pv = init()
    while true
        input = split(readline())
        if "uci" in input
            println("id name ", ENINGENAME)
            println("id author ", AUTHOR)
            println("uciok")
            println("Threads: ", Threads.nthreads())
            println(threadid())
        elseif "isready" in input
            println("readyok")
        elseif "ucinewgame" in input
            clear_hash_table(pv)
            for i in 1:1:length(pv.repetition)
                pv.repetition[i] = 0
            end
        elseif "new" in input
            clear_hash_table(pv)
            for i in 1:1:length(pv.repetition)
                pv.repetition[i] = 0
            end
        elseif "position" in input
            if "startpos" in input
                board = startboard()
                if "moves" in input
                    pv.hisPly[1] = 0
                    i = indexin(["moves"], input)[1] + 1
                    n = length(input)
                    for index in i:n
                        if threadid() == 1
                            pv.repetition[pv.hisPly[1] + 1] = board.key
                            pv.hisPly[1] += 1
                            move = string(input[index])
                            # println(move)
                            domove!(board, move)
                            
                            #println(pv.hisPly[1])
                        end
                    end
                end
            
            elseif "fen" in input
                i = indexin(["fen"], input)[1]
                string1 = string(input[i + 1])
                string2 = string(input[i + 2])
                string3 = string(input[i + 3])
                string4 = string(input[i + 4])
                string5 = string(input[i + 5])
                string6 = string(input[i + 6])
                println(string1, " ", string2, " ", string3, " ", string4, " ", string5, " ", string6)
                board = fromfen(string(string1, " ", string2, " ", string3, " ", string4, " ", string5, " ", string6))
                
                if "moves" in input
                    pv.hisPly[1] = 0
                    i = indexin(["moves"], input)[1] + 1
                    n = length(input)
                    for index in i:n
                        pv.repetition[pv.hisPly[1] + 1] = board.key
                        pv.hisPly[1] += 1
                        move = string(input[index])
                        domove!(board, move)
                        
                    end
                    println(pv.repetition)

                end
            end
        elseif "go" in input
            if "wtime" in input
                
                white_time_index = indexin(["wtime"], input)[1] + 1
                global white_time = parse(Float64, input[white_time_index])
                global timecontrol = true
                
            end
            if "btime" in input
                black_time_index = indexin(["btime"], input)[1] + 1
                global black_time = parse(Float64, input[black_time_index])
                global timecontrol = true
                
            end
            if "winc" in input
                wincrementindex = indexin(["winc"], input)[1] + 1
                global wincrement = parse(Float64, input[wincrementindex])
                global white_time += wincrement
            end
            if "binc" in input
                blackincrementindex = indexin(["binc"], input)[1] + 1
                global blackincrement = parse(Float64, input[blackincrementindex])
                global black_time += blackincrement
            end
            posKey = board.key
            move =  calc_best_move(board, 20, pv, key, posKey)
            if move != nothing
                move = tostring(move)
            else
                move = tostring(moves(board)[1])
            end
            println("bestmove ", move)
            
        end
       	if "stop" in input
       	    global timecontrol = true
            global calculating = false
       	end
        if "quit" in input
            exit()
        end
    end
end

precompile(uciCommunication, (String, String))
uciCommunication()
