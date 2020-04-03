using Chess, Chess.Book
include("minmax.jl")

function uciCommunication()
    ENINGENAME = "strudlsjuliachessv0.1"
    AUTHOR = "strudl"
    board = startboard()
    
    while true
        input = split(readline())
        if "uci" in input
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
            end
        elseif "go" in input
	    #why is depth 4 better than 5!?
            move = calc_best_move(board, 3)
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
