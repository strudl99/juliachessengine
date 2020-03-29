using Chess, Chess.Book
include("minmax.jl")

# function to play game against itself

function play_game()
    @time begin
        g = Game()
    
        
        number_moves = 0
        while !isterminal(g)
            b = board(g)
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
                domove!(g, move)  
            else
                move = calc_best_move(b, 3, true, number_moves)
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
                domove!(g, move)
            end
        end
        
        
        print(g)
        

    end
end
