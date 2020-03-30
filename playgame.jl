

# function to play game against itself

function play_game()
    print("Welcome to Juliachess, do you want to be white or black [w] b: ")
    player = readline()
    println(player)
    g = Game()
    isplayerblack = false
    if(player == "b")
        isplayerblack = true
    end
    println(isplayerblack)

    number_moves = 0
    while !isterminal(g)
        b = board(g)
        if sidetomove(b) == WHITE
            number_moves += 1
            if isplayerblack == true
                move = calc_best_move(b, 5, false, number_moves)
                move =  movetosan(b, move)
            else
                print("Move: ")
                move = readline()
            end
            if move == Nothing
                if ischeck(b)
                    println("Checkmate Black")
                    break
                else
                    println("DRAW")
                    break
                end
            end
            print("bestmove ", move)
            domove!(g, move)  
        else
            if isplayerblack == false
                move = calc_best_move(b, 5, false, number_moves)
                move = movetosan(b, move)
            else
                print("Move: ")
                move = readline()
            end
            if move === nothing
                if ischeck(b)
                    println("Checkmate White")
                    break
                else
                    println("DRAW")
                    break
                end
            end
            print("bestmove ", move, " ")
            domove!(g, move)
        end
    end
        
    return number_moves
    print(g)
    
    
end


function benchmark()
    e = 0
    n = 0
    for i in range(1, stop = 3, step = 1)
        e0 = 0
        e += @elapsed n += play_game()
        e += e0
    end
    print("\n")
    println(e / 5)
    println(n)
    println("Average time per move: ", e / n)

end


