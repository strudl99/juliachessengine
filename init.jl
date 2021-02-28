include("pvtable.jl")

function init()
    squareKeys = []
    pieceKeys = []
    sideKey = 0
    castle_key = 0
    index_rep = 1
    how_many_reps = 0
    pv_table = []
    history = []
    repetition = Array{Int128, 1}(undef, 1)
    ply = 0 ::Int
    killer_moves = Array{Move, 2}(undef, 2,20)
    nodes = 0::Int
    mvvlva_scores = zeros(12, 12)
    searchHistory = zeros(Int32,64,64)::Array{Int32,2}
    PVSIZE = 81920::Int # 1 zeile Dict hat 64 byte
    white_passed_mask = []
    black_passed_mask = []
    hisPly = 0
    isoloni_mask = []
    moveList = MoveList(200)
    side = WHITE
    pv = Pv(pv_table, PVSIZE, history, repetition, mvvlva_scores, killer_moves, index_rep, how_many_reps, ply, hisPly, searchHistory, white_passed_mask, black_passed_mask, isoloni_mask, moveList, side)
    init_mvvlva(pv)
    keys = Keys(nodes)
    pv = Init_Pv_Table(pv)

    return keys, pv
end

function init_mvvlva(pv::Pv)
    victim_scores = [100, 200, 300, 400, 500, 600, 100, 200, 300, 400, 500, 600, 0]
    piece_list = [PIECE_WP, PIECE_WN, PIECE_WB, PIECE_WR, PIECE_WQ, PIECE_WK,PIECE_BP, PIECE_BN, PIECE_BB, PIECE_BR, PIECE_BQ, PIECE_BK]
    for (i, attacker) in enumerate(piece_list)
        for (j, victim) in enumerate(piece_list)
            if attacker == piece_list[i] && victim == piece_list[j]
                pv.mvvlva_scores[i, j] = victim_scores[i] + 6 - (victim_scores[j] / 100)
            end
        end
    end
end