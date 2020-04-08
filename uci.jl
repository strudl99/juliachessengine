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
                        println(move)
                        domove!(board, move)
                    end

                end
            
            elseif "fen" in input
                i = indexin(["fen"], input)[1]
                board = fromfen(string(input[i + 1]))
                if "moves" in input
                    i = indexin(["moves"], input)[1] + 1
                    n = length(input)
                    for index in i:n
                        move = string(input[index])
                        println(move)
                        domove!(board, move)
                    end

                end
            end
        elseif "go" in input
            if "wtime" in input
                white_time_index = indexin(["wtime"], input)[1] + 1
                global white_time = parse(Int, input[white_time_index])
                global timecontrol = true
                
            end
            if "btime" in input
                black_time_index = indexin(["btime"], input)[1] + 1
                global black_time = parse(Int, input[black_time_index])
                global timecontrol = true
                
            end
            move = calc_best_move(board, 5)
            if move != nothing
                move = tostring(move)
            else
                move = tostring(moves(board)[1])
            end
            println("bestmove ", move)
            println(board)
            
        end
       	if "stop" in input
       	    break
       	end
        if "quit" in input
            break
        end
    end
end

precompile(uciCommunication, (String, String))
uciCommunication()
