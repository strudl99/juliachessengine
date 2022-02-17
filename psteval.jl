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
const SHIELD1 = 10
const SHIELD2 = 5
function wKingShield(b::Board)
    Score = 0
    ## If the king is castled on the kingside
    if file(Square(b.ksq[1])) > FILE_E
        if pieceon(b, SQ_F2) == PIECE_WP
            Score += SHIELD1
        elseif pieceon(b, SQ_F3) == PIECE_WP
            Score += SHIELD2
        end
        if pieceon(b, SQ_G2) == PIECE_WP
            Score += SHIELD1
        elseif pieceon(b, SQ_G3) == PIECE_WP
            Score += SHIELD2
        end
        if pieceon(b, SQ_H2) == PIECE_WP
            Score += SHIELD1
        elseif pieceon(b, SQ_H3) == PIECE_WP
            Score += SHIELD2
        end
    ## If castled on the queenside
    elseif file(Square(b.ksq[1])) < FILE_D
        if pieceon(b, SQ_A2) == PIECE_WP
            Score += SHIELD1
        elseif pieceon(b, SQ_A3) == PIECE_WP
            Score += SHIELD2
        end
        if pieceon(b, SQ_B2) == PIECE_WP
            Score += SHIELD1
        elseif pieceon(b, SQ_B3) == PIECE_WP
            Score += SHIELD2
        end
        if pieceon(b, SQ_C2) == PIECE_WP
            Score += SHIELD1
        elseif pieceon(b, SQ_C3) == PIECE_WP
            Score += SHIELD2
        end
    end
    return Score
end

function bKingShield( b::Board)
    ## If the king is castled on the kingside
    Score = 0
    if file(Square(b.ksq[2])) > FILE_E
        if pieceon(b, SQ_F7) == PIECE_BP
            Score += SHIELD1
        elseif pieceon(b, SQ_F6) == PIECE_BP
            Score += SHIELD2
        end
        if pieceon(b, SQ_G7) == PIECE_BP
            Score += SHIELD1
        elseif pieceon(b, SQ_G6) == PIECE_BP
            Score += SHIELD2
        end
        if pieceon(b, SQ_H7) == PIECE_BP
            Score += SHIELD1
        elseif pieceon(b, SQ_H6) == PIECE_BP
            Score += SHIELD2
        end
    ## If castled on the queenside
    elseif file(Square(b.ksq[2])) < FILE_D
        if pieceon(b, SQ_A7) == PIECE_BP
            Score += SHIELD1
        elseif pieceon(b, SQ_A6) == PIECE_BP
            Score += SHIELD2
        end
        if pieceon(b, SQ_B7) == PIECE_BP
            Score += SHIELD1
        elseif pieceon(b, SQ_B6) == PIECE_BP
            Score += SHIELD2
        end
        if pieceon(b, SQ_C7) == PIECE_BP
            Score += SHIELD1
        elseif pieceon(b, SQ_C6) == PIECE_BP
            Score += SHIELD2
        end
    end
    return Score
end

function isPawnSupported(b::Board, square::Square, side)
    shiftSquareSet = side == WHITE ? shift_s(SquareSet(square)) : shift_n(SquareSet(square))
    if !isempty(intersect(shift_w(shiftSquareSet), pawns(b, side)))
        return true
    end
    if !isempty(intersect(shift_e(shiftSquareSet), pawns(b, side)))
        return true
    end
    return false

end
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
        if !isPawnSupported(b, square, WHITE)
            Score -= 5
        end
        if isempty(intersect(pv.white_passed_mask[convertToHorizontal[square.val]], pawns(b, BLACK)))
            if isPawnSupported(b, square, WHITE)
                Score += convert(Int64, round((pawn_passed[rank(square).val] * 10) / 8, digits=0))
            else
                Score += pawn_passed[rank(square).val]
            end
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

        if isempty(intersect(pawns(b), files[file(square).val]))
            Score += ROOK_OPEN_FILE
        elseif isempty(intersect(pawns(b, WHITE), files[file(square).val]))
            Score += ROOK_SEMI_OPEN_FILE
        end   
    end
    if !isempty(queens(b, WHITE))
        Queen = 1
    end
    if Bishops == 2
        Score += 30
    end
    mg = Score
    eg = Score

    @inbounds for square in kings(b, WHITE)
        mg += king_square_table[convertToHorizontal[square.val]]
        # King Safety
        mg += wKingShield(b)


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
        Score += pawn_square_table[mirror64[convertToHorizontal[square.val]]]::Int 
        Pawns += 1
        if !isPawnSupported(b, square, BLACK)
            Score -= 5
        end
        if isempty(intersect(pv.black_passed_mask[mirror64[convertToHorizontal[square.val]]], pawns(b, WHITE)))
            if isPawnSupported(b, square, BLACK)
                Score += convert(Int64, round((pawn_passed_black[rank(square).val] * 10) / 8, digits=0))
            else
                Score += pawn_passed_black[rank(square).val] 
            end
        end
         if isempty(intersect(pv.isoloni_mask[mirror64[convertToHorizontal[square.val]]], pawns(b, BLACK)))
            Score += ISOLATED_PAWN
            #println("ISOLONI : ", bpawn_squares[i])
        end    
    end
    @inbounds for square in bishops(b, BLACK)
        Score += bishop_square_table[mirror64[convertToHorizontal[square.val]]]::Int 
        Bishops += 1
    end
    @inbounds for square in knights(b, BLACK)
        Score += knight_square_table[mirror64[convertToHorizontal[square.val]]]::Int 
        Knights += 1
    end
    @inbounds for square in rooks(b, BLACK)
        Score += rook_square_table[mirror64[convertToHorizontal[square.val]]]::Int 
        Rooks += 1
        if isempty(intersect(pawns(b), files[file(square).val]))
            Score += ROOK_OPEN_FILE
        elseif isempty(intersect(pawns(b, BLACK), files[file(square).val]))
            Score += ROOK_SEMI_OPEN_FILE
        end   
    end
    if !isempty(queens(b, BLACK))
        Queen = 1
    end
    if Bishops == 2
        Score += 30
    end
    mg = Score
    eg = Score

    @inbounds for square in kings(b, BLACK)
        mg += king_square_table[mirror64[convertToHorizontal[square.val]]]
        mg += bKingShield(b)
        eg += king_endgame_square_table[mirror64[convertToHorizontal[square.val]]]
    end

    return -mg, -eg, Pawns, Bishops, Knights, Rooks, Queen

end

function evaluate_board(b::Board, pv::Pv)
    wMg, wEg, wP, wB, wK, wR, wQ = pstEvalWhite(b, pv)
    bMg, bEg, bP, bB, bK, bR, bQ = pstEvalBlack(b, pv)
    wMaterial = wP * 100 + wK * 325 + wB * 335 + wR * 550 + wQ * 1000
    bMaterial = bP * 100 + bK * 325 + bB * 335 + bR * 550 + bQ * 1000
    #println(bMg)
    #println(wMg)
    materialBalance = wMaterial - bMaterial
    mgScore = (wMg + bMg) + materialBalance
    egScore = (wEg + bEg) + materialBalance
    phase = TotalPhase
    phase -= wK * KnightPhase
    phase -= wB  * BishopPhase
    phase -= wR  * RookPhase
    phase -= wQ  * QueenPhase
    phase -= bK * KnightPhase
    phase -= bB  * BishopPhase
    phase -= bR  * RookPhase
    phase -= bQ  * QueenPhase
    if phase > 24
        phase = 24
    end
    eg_phase = phase
    mg_phase = 24 - phase 
#=     println(eg_phase)
    println(mg_phase)  =#
    #println(mgScore)
    #println(egScore)
    #
    result = (mgScore * mg_phase + egScore * eg_phase) / 24
    #println(result)
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