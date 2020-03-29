using Chess, Chess.Book
include("minmax.jl")

# function to play game against itself

function play_game()
    b = startboard()
    number_moves = 0
    while !isterminal(b)
        if sidetomove(b) == WHITE
            number_moves += 1
            move = calc_best_move(b, 5, false, number_moves)
            if move == Nothing
                if ischeck(b)
                    println("Checkmate Black")
                    break
                else
                    println("DRAW")
                    break
                end
            end
            print(number_moves, ". ", movetosan(b, move))
            
        else
            move = calc_best_move(b, 5, true, number_moves)
            if move === nothing
                if ischeck(b)
                    println("Checkmate White")
                    break
                else
                    println("DRAW")
                    break
                end
            end
            print(" ", movetosan(b, move), " ")
        end
        domove!(b, move)

    end
end
