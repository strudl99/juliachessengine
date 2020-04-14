using Chess, Chess.Book
include("minmax.jl")
white_time = 0
black_time = 0
timecontrol = false
function uciCommunication()
    ENINGENAME = "strudlsjuliachessv0.5"
    AUTHOR = "strudl"
    board = startboard()
    
    while true
        input = split(readline())
        if "uci" in input
            Init_Pv_Table()
            InitHashKeys()
            Init_search_history()
            init_mvvlva()
            init_eval_masks()
            println("id name ", ENINGENAME)
            println("id author ", AUTHOR)
            println("uciok")
        elseif "isready" in input
            
            println("readyok")
        elseif "ucinewgame" in input
            board = startboard()
        elseif "position" in input
            if "startpos" in input
                board = startboard()
                if "moves" in input
                    i = indexin(["moves"], input)[1] + 1
                    n = length(input)
                    for index in i:n
                        move = string(input[index])
                        # println(move)
                        domove!(board, move)
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
                    i = indexin(["moves"], input)[1] + 1
                    n = length(input)
                    for index in i:n
                        move = string(input[index])
                        # println(move)
                        domove!(board, move)
                    end

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
            move = calc_best_move(board, 8)
            if move != nothing
                move = tostring(move)
            else
                move = tostring(moves(board)[1])
            end
            println("bestmove ", move)
            
        end
       	if "stop" in input
       	    exit(1)
       	end
        if "quit" in input
            exit(1)
        end
    end
end

precompile(uciCommunication, (String, String))
uciCommunication()
