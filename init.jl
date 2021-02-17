include("pvtable.jl")

function init()
    squareKeys = []
    pieceKeys = []
    sideKey = 0
    castle_key = 0
    index_rep = 1
    how_many_reps = 0
    pv_table = []
    history = []::Array
    repetition = []::Array
    ply = 0
    killer_moves = [(MOVE_NULL, 0), (MOVE_NULL, 0), 0]
    nodes = 0::Int
    mvvlva_scores = zeros(12, 12)
    searchHistory = []
    PVSIZE = 506 # 1 zeile Dict hat 8 byte
    white_passed_mask = []
    black_passed_mask = []
    isoloni_mask = []
    moveList = MoveList(200)
    pv = Pv(pv_table, PVSIZE, history, repetition, mvvlva_scores, killer_moves, index_rep, how_many_reps, ply, searchHistory, white_passed_mask, black_passed_mask, isoloni_mask, moveList)
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