include("minmax.jl")
include("init.jl")
import Base.copy

function threads()
    board1 = fromfen("rnbqk1nr/p4b2/8/2ppN1pP/6p1/2P5/RK3P1P/1N1B1B1R w Kkq -")
    board2 = fromfen("rnbqk1nr/p4b2/8/2ppN1pP/6p1/2P5/RK3P1P/1N1B1B1R w Kkq -")
    key1, pv = init()
    key2, pv2 = init()
    depth1 = 3
    depth2 = 3
    firstTask = Threads.@spawn begin
        calc_best_move(board1, depth1, pv, key1, 0)
    end
    secondTask = Threads.@spawn begin
        calc_best_move(board2, depth2, pv2, key2, 0)
    end
    wait(firstTask)
    wait(secondTask)
end


#debugThreads()