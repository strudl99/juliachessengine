include("minmax.jl")

function commands()
    b = startboard()
    key, pv = init()
    global bench = false
    pv.hisPly[1] = 0
    while true
        input = split(readline())
        
        if "move" in input
            try
                i = indexin(["move"], input)[1]
                pv.repetition[pv.hisPly[1] + 1] = b.key
                pv.hisPly[1] += 1
                domove!(b, string(input[i+1]))
                println(b)
            catch
                print("Not existing move!")
            end
            
        end
        if "fen" in input
            i = indexin(["fen"], input)[1]
            string1 = string(input[i + 1])
            string2 = string(input[i + 2])
            string3 = string(input[i + 3])
            string4 = string(input[i + 4])
            string5 = string(input[i + 5])
            string6 = string(input[i + 6])
            println(string1, " ", string2, " ", string3, " ", string4, " ", string5, " ", string6)
            b = fromfen(string(string1, " ", string2, " ", string3, " ", string4, " ", string5, " ", string6))
        end
        if "repetition" in input
            println(repetition(b, pv, 1))
        end
        if "search" in input
            i = indexin(["search"], input)[1]
            calc_best_move(b, parse(Int64, string(input[i + 1])), pv, key, 0)
        end
    end

end
commands()