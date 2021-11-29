using Base: threadid
using Chess.Book: Threads
using Chess.Book: Threads

include("minmax.jl")
# function to play game against itself
function play_game()
    print("Welcome to Juliachess, do you want to be white or black [w] b: ")
    player = readline()
    println(player)
    g = Game()
    key,  pv = init()
    isplayerblack = false
    isplayerboth = true
    if(player == "b")
        isplayerblack = true
    end
    println(isplayerblack)

    number_moves = 0
    while !isterminal(g)
        b = board(g)
        if sidetomove(b) == WHITE
            
            number_moves += 1
            if isplayerboth
                print("Move: ")
                move = readline()
            elseif isplayerblack == true 
                move = calc_best_move(b, 7, pv, key, b.key)
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
            println("bestmove ", move)
            println("Repetiton: ", repetition(b, pv))
            println("PV", pv.repetition)
            println("move 50: ", b.r50)
            push!(pv.repetition, b.key)
            domove!(g, move)  
        else
            if isplayerboth
                print("Move: ")
                move = readline()
            elseif isplayerblack == false 
                move = calc_best_move(b, 7, pv, key, b.key)
                move = movetosan(b, move)
                print("Move: ")
                move = readline()
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
            println("bestmove ", move, " ")
            println("Repetiton: ", repetition(b, pv))
            println("PV", pv.repetition)
            println("move 50: ", b.r50)
            push!(pv.repetition, b.key)
            domove!(g, move)
        end
    end
    println(g)
    return number_moves
    
    
    
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
