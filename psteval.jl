using Chess, Chess.Book
using Random
include("movegen.jl")
include("init.jl")

const pawn_passed = [200, 100, 60, 35, 20, 10, 5, 0]
const pawn_passed_black = [0, 5, 10, 20, 35, 60, 100, 200]
const pawn_square_table = [
    0,	0,	0,	0,	0,	0,	0,	0,
	10,	10,	0,	-10,-10,0,	10,	10,
	5,	0,	0,	5,	5,	0,	0,	5,
	0,	0,	10,	20,	20,	10,	0,	0,
	5,	5,	5,	10,	10,	5,	5,	5,
	10,	10,	10,	20,	20,	10,	10,	10,
	20,	20,	20,	30,	30,	20,	20,	20,
	0,	0,	0,	0,	0,	0,	0,	0
]

const knight_square_table = [
    0,	-10,0,	0,	0,	0,	-10,0,
	0,	0,	0,	5,	5,	0,	0,	0,
	0,	0,	10,	10,	10,	10,	0,	0,
	0,	0,	10,	20,	20,	10,	5,	0,
	5,	10,	15,	20,	20,	15,	10,	5,
	5,	10,	10,	20,	20,	10,	10,	5,
	0,	0,	5,	10,	10,	5,	0,	0,
	0,	0,	0,	0,	0,	0,	0,	0
]

const bishop_square_table = [
    0,	0,	-10,0,	0,	-10,0,	0,
	0,	0,	0,	10,	10,	0,	0,	0,
	0,	0,	10,	15,	15,	10,	0,	0,
	0,	10,	15,	20,	20,	15,	10,	0,
	0,	10,	15,	20,	20,	15,	10,	0,
	0,	0,	10,	15,	15,	10,	0,	0,
	0,	0,	0,	10,	10,	0,	0,	0,
	0,	0,	0,	0,	0,	0,	0,	0
    ]

const rook_square_table = [
    0,	0,	5,	10,	10,	5,	0,	0,
	0,	0,	5,	10,	10,	5,	0,	0,
	0,	0,	5,	10,	10,	5,	0,	0,
	0,	0,	5,	10,	10,	5,	0,	0,
	0,	0,	5,	10,	10,	5,	0,	0,
	0,	0,	5,	10,	10,	5,	0,	0,
	25,	25,	25,	25,	25,	25,	25,	25,
	0,	0,	5,	10,	10,	5,	0,	0
     ]


const king_square_table = 
[
    0,	0,	-10, -10, -10,0, 20, 5,
	-30,-30,-30,-30,-30,-30,-30,-30,
	-50,-50,-50,-50,-50,-50,-50,-50,
	-70,-70,-70,-70,-70,-70,-70,-70,
	-70,-70,-70,-70,-70,-70,-70,-70,
	-70,-70,-70,-70,-70,-70,-70,-70,
	-70,-70,-70,-70,-70,-70,-70,-70,
	-70,-70,-70,-70,-70,-70,-70,-70	
]

const king_endgame_square_table = [
    -50,-10,0,	0,	0,	0,	-10,-50,
	-10,0,	10,	10,	10,	10,	0,	-10,
	0,	10,	15,	15,	15,	15,	10,	0,
	0,	10,	15,	20,	20,	15,	10,	0,
	0,	10,	15,	20,	20,	15,	10,	0,
	0,	10,	15,	15,	15,	15,	10,	0,
	-10,0,	10,	10,	10,	10,	0,	-10,
	-50,-10,0,	0,	0,	0,	-10,-50
]

const convertToHorizontal = [
    57, 49, 41, 33, 25, 17, 9, 1,
    58, 50, 42, 34, 26, 18, 10, 2,
    59, 51, 43, 35, 27, 19, 11, 3,
    60, 52, 44, 36, 28, 20, 12, 4,
    61, 53, 45, 37, 29, 21, 13, 5,
    62, 54, 46, 38, 30, 22, 14, 6,
    63, 55, 47, 39, 31, 23, 15, 7,
    64, 56, 48, 40, 32, 24, 16, 8 
]

const mirror64 = [
    57, 58, 59, 60, 61, 62, 63, 64, 
    49, 50, 51, 52, 53, 54, 55, 56, 
    41, 42, 43, 44, 45, 46, 47, 48, 
    33, 34, 35, 36, 37, 38, 39, 40, 
    25, 26, 27, 28, 29, 30, 31, 32, 
    17, 18, 19, 20, 21, 22, 23, 24, 
    9, 10, 11, 12, 13, 14, 15, 16, 
    1, 2, 3, 4, 5, 6, 7, 8,
]
const files = [SS_FILE_A, SS_FILE_B, SS_FILE_C, SS_FILE_D, SS_FILE_E, SS_FILE_F, SS_FILE_G, SS_FILE_H]
const endgame = false
const ISOLATED_PAWN = -10
const ROOK_OPEN_FILE = 10
const ROOK_SEMI_OPEN_FILE = 5
const QUEEN_OPEN_FILE = 5
const QUEEN_SEMI_OPEN_FILE = 3
const KnightPhase = 1
const BishopPhase = 1
const RookPhase = 2
const QueenPhase = 4
const TotalPhase = KnightPhase*4 + BishopPhase*4 + RookPhase*4 + QueenPhase*2

function pstEvalWhite(b::Board, pv::Pv)
    Score =   0
    Pawns =   0
    Bishops = 0
    Knights = 0
    Rooks =   0
    Queen =   0
    ## Pawn evaluation with passed pawn and isolani
    @inbounds for square in pawns(b, WHITE)
        Score += pawn_square_table[convertToHorizontal[square.val]]::Int 
        Pawns += 1
        if isempty(intersect(pv.white_passed_mask[convertToHorizontal[square.val]], pawns(b, BLACK)))
            Score += pawn_passed[rank(square).val]
                #println(pawn_passed[rank(wpawn_squares[i]).val]) 
               # println("PASSER : ", wpawn_squares[i])
        end
         if isempty(intersect(pv.isoloni_mask[convertToHorizontal[square.val]], pawns(b, WHITE)))
            Score += ISOLATED_PAWN
            #println("ISOLONI : ", wpawn_squares[i])
        end  
    end
    @inbounds for square in bishops(b, WHITE)
        Score += bishop_square_table[convertToHorizontal[square.val]]::Int 
        Bishops += 1
    end
    @inbounds for square in knights(b, WHITE)
        Score += knight_square_table[convertToHorizontal[square.val]]::Int 
        Knights += 1
    end
    @inbounds for square in rooks(b, WHITE)
        Score += rook_square_table[convertToHorizontal[square.val]]::Int 
        Rooks += 1
    end
    if !isempty(queens(b, WHITE))
        Queen = 1
    end
    mg = Score
    eg = Score

    @inbounds for square in kings(b, WHITE)
        mg += king_square_table[convertToHorizontal[square.val]]
        eg += king_endgame_square_table[convertToHorizontal[square.val]]
    end

    return mg, eg, Pawns, Bishops, Knights, Rooks, Queen

end

function pstEvalBlack(b::Board, pv::Pv)
    Score =   0
    Pawns =   0
    Bishops = 0
    Knights = 0
    Rooks =   0
    Queen =   0
    ## Pawn evaluation with passed pawn and isolani
    @inbounds for square in pawns(b, BLACK)
        Score -= pawn_square_table[mirror64[convertToHorizontal[square.val]]]::Int 
        Pawns += 1
        if isempty(intersect(pv.black_passed_mask[mirror64[convertToHorizontal[square.val]]], pawns(b, WHITE)))
            Score -= pawn_passed_black[rank(square).val] 
        end
         if isempty(intersect(pv.isoloni_mask[mirror64[convertToHorizontal[square.val]]], pawns(b, BLACK)))
            Score -= ISOLATED_PAWN
            #println("ISOLONI : ", bpawn_squares[i])
        end    
    end
    @inbounds for square in bishops(b, BLACK)
        Score -= bishop_square_table[mirror64[convertToHorizontal[square.val]]]::Int 
        Bishops += 1
    end
    @inbounds for square in knights(b, BLACK)
        Score -= knight_square_table[mirror64[convertToHorizontal[square.val]]]::Int 
        Knights += 1
    end
    @inbounds for square in rooks(b, BLACK)
        Score -= rook_square_table[mirror64[convertToHorizontal[square.val]]]::Int 
        Rooks += 1
    end
    if !isempty(queens(b, BLACK))
        Queen = 1
    end
    mg = Score
    eg = Score

    @inbounds for square in kings(b, BLACK)
        mg -= king_square_table[mirror64[convertToHorizontal[square.val]]]
        eg -= king_endgame_square_table[mirror64[convertToHorizontal[square.val]]]
    end

    return mg, eg, Pawns, Bishops, Knights, Rooks, Queen

end

function evaluate_board(b::Board, pv::Pv)
    wMg, wEg, wP, wB, wK, wR, wQ = pstEvalWhite(b, pv)
    bMg, bEg, bP, bB, bK, bR, bQ = pstEvalBlack(b, pv)
    wMaterial = wP * 100 + wK * 325 + wB * 335 + wR * 550 + wQ * 1000
    bMaterial = bP * 100 + bK * 325 + bB * 335 + bR * 550 + bQ * 1000
    materialBalance = wMaterial - bMaterial
    mgScore = (wMg + bMg) + materialBalance
    egScore = (wEg + bEg) + materialBalance
    phase = 0
    phase += wK * KnightPhase
    phase += wB  * BishopPhase
    phase += wR  * RookPhase
    phase += wQ  * QueenPhase
    phase += bK * KnightPhase
    phase += bB  * BishopPhase
    phase += bR  * RookPhase
    phase += bQ  * QueenPhase

    if phase > 24
        phase = 24
    end
    eg_phase = 24 - phase 
    result = (mgScore * phase + egScore * eg_phase) / 24
    if sidetomove(b) == WHITE
        #score += (movecount(b))
        return convert(Int64, round(result, digits=0))
    else
        #score -= (movecount(b))
        return -convert(Int64, round(result, digits=0))
    end 
end

function big_piece(chessboard)::Bool
    if !isempty(bishops(chessboard)) || !isempty(knights(chessboard)) || !isempty(rooks(chessboard)) || !isempty(queens(chessboard)) 
        return true
    end
    return false
end
function mirror()
    key, pv = init()
    fens = readlines("testpositions.txt")
    for i=1:1:length(fens)
        if i % 1000 == 0
            println(i, " Positions done")
        end
        chessboard = fromfen(fens[i])
        before_mirror = evaluate_board(chessboard, pv)
        #println("Befor mirror: ", before_mirror)
        #println("Hashkey: ", chessboard.key)
        #println(chessboard)
        chessboard = flip(chessboard)
        after_mirror = evaluate_board(chessboard, pv)
        if after_mirror != before_mirror
            println("Not passed fen : ", fens[i])
            println("Befor mirror: ", before_mirror)
            println("After mirror: ", after_mirror)
            break
        end
        #println("After mirror: ", after_mirror)
        #println("Hashkey: ", chessboard.key)
        #println(chessboard)
        chessboard = flip(chessboard)
    end
end