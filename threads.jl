include("minmax.jl")
include("init.jl")
function threads(board, depth, pv, key)
    firstTask = Threads.@spawn begin
        calc_best_move(board, depth, pv, key, 0)
    end
    secondTask = Threads.@spawn begin
        calc_best_move(board, depth, pv, key, 0)
    end

end

function debugThreads()
    b = fromfen("rnbqk1nr/p4b2/8/2ppN1pP/6p1/2P5/RK3P1P/1N1B1B1R w Kkq -")
    key, pv = init()
    println("INIT DONE")
    threads(b, 3, pv, key)
end


#debugThreads()