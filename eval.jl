using Chess, Chess.Book
using Random
include("movegen.jl")
black_passed_mask = []
white_passed_mask = []

isolated_passed_mask = zeros(UInt, 64)
const pawn_passed = [200, 100, 50, 35, 20, 10, 5, 0]
const pawn_square_table = [
    0, 50, 10, 5, 0, 5, 5, 0,
    0, 50, 10, 5, 0, -5, 10, 0,
    0, 50, 20, 10, 0, -10, 10,0,
    0, 50, 30, 25, 20, 0, -20, 0,
    0, 50, 30, 25, 20, 0, -20, 0,
    0, 50, 20, 10, 0, -10, 10, 0,
    0, 50, 10, 5, 0, -5, 10, 0,
    0, 50, 10, 5, 0, 5, 5, 0
]

const knight_square_table = [
    -50,-40,-30,-30,-30,-30,-40,-50,
    -40,-20,  0,  5,  0,  5,-20,-40,
    -30,  0, 10, 15, 15, 10,  0,-30,
    -30,  0, 15, 20, 20, 15,  5,-30,
    -30,  0, 15, 20, 20, 15,  5,-30,
    -30,  0, 10, 15, 15, 10,  0,-30,
    -40,-20,  0,  5,  0,  5,-20,-40,
    -50,-40,-30,-30,-30,-30,-40,-50
]

const bishop_square_table = [
    -20,-10,-10,-10,-10,-10,-10,-20,
    -10,  0,  0,  5,  0, 10,  5,-10,
    -10,  0,  5,  5, 10, 10,  0,-10,
    -10,  0, 10, 10, 10, 10,  0,-10,
    -10,  0, 10, 10, 10, 10,  0,-10,
    -10,  0,  5,  5, 10, 10,  0,-10,
    -10,  0,  0,  0,  0, 10,  5,-10,
    -20,-10,-10,-10,-10,-10,-10,-20
    ]

const rook_square_table = [
     0, 5, -5, -5, -5, -5, -5, 0,
     0, 10, 0, 0, 0, 0, 0, 0,
     0, 10, 0, 0, 0, 0, 0, 0,
     0, 10, 0, 0, 0, 0, 0, 5, 
     0, 10, 0, 0, 0, 0, 0, 5,
     0, 10, 0, 0, 0, 0, 0, 0,
     0, 10, 0, 0, 0, 0, 0, 0,
     0, 5, -5, -5, -5, -5, -5, 0
     ]

const queen_square_table = [
    -20, -10, -10, -5, 0, -10, -10, -20,
    -10, 0, 0, 0, 0, 5, 0, -10,
    -10, 0, 5, 5, 5, 5, 5, -10, 
    -5, 0, 5, 5, 5, 5, 0, -5, 
    -5, 0, 5, 5, 5, 5, 0, -5,
    -10, 0, 5, 5, 5, 5, 0, -10,
    -10, 0, 0, 0, 0, 0, 0, -10,
    -20, -10, -10, -5, -5, -10, -10, -20,

]

const king_square_table = 
[
    -30, -30, -30, -30, -20, -10, 20, 20,
    -40, -40, -40, -40, -30, -20, 20, 30, 
    -40, -40, -40, -40, -30, -20, 0, 10,
    -50, -50, -50, -50, -40, -20, 0, 0,
    -50, -50, -50, -50, -40, -20, 0, 0, 
    -40, -40, -40, -40, -30, -20, 0, 10, 
    -40, -40, -40, -40, -30, -20, 20, 30, 
    -30, -30, -30, -30, -20, -10, 20, 20
]

const king_endgame_square_table = [
    -50, -30, -30, -30, -30, -30, -30, -50,
    -40, -20, -10, -10, -10, -10, -30, -30,
    -30, -10, 20, 30, 30, 20, 0, -30,
    -20, 0, 30, 40, 40, 30, 0, -30,
    -20, 0, 30, 40, 40, 30, 0, -30,
    -30, -10, 20, 30, 30, 20, 0, -30,
    -40, -20, -10, -10, -10, -10, -30, -30,
    -50, -30, -30, -30, -30, -30, -30, -50
]
const mirror64 = [
    8,7,6,5,4,3,2,1,
    16,15,14,13,12,11,10,9,
    24,23,22,21,20,19,18,17,
    32,31,30,29,28,27,26,25,
    40,39,38,37,36,35,34,33,
    48,47,46,45,44,43,42,41,
    56,55,54,53,52,51,50,49,
    64,63,62,61,60,59,58,57
]

const convertToHorizontalwhite = [
    57, 49, 41, 33, 25, 17, 9, 1,
    58, 50, 42, 34, 26, 18, 10, 2,
    59, 51, 43, 35, 27, 19, 11, 3,
    60, 52, 44, 36, 28, 20, 12, 4,
    61, 53, 45, 37, 29, 21, 13, 5,
    62, 54, 46, 38, 30, 22, 14, 6,
    63, 55, 47, 39, 31, 23, 15, 7,
    64, 56, 48, 40, 32, 24, 16, 8 
]

const convertToHorizontalblack = [
    1, 9, 17, 25, 33, 41, 49, 57,
    2, 10, 18, 26, 34, 42, 50, 58,
    3, 11, 19, 27, 35, 43, 51, 59, 
    4, 12, 20, 28, 36, 44, 52, 60,
    5, 13, 21, 29, 37, 45, 53, 61, 
    6, 14, 22, 30, 38, 46, 54, 62,
    7, 15, 23, 31, 39, 47, 55, 63, 
    8, 16, 24, 32, 40, 48, 56, 64
]
endgame = false::Bool

function piece_value(b::Board, pv::Pv)::Int
    files = [SS_FILE_A, SS_FILE_B, SS_FILE_C, SS_FILE_D, SS_FILE_E, SS_FILE_F, SS_FILE_G, SS_FILE_H]
    score = 0::Int
    endgame = false
    ISOLATED_PAWN = -10
    ROOK_OPEN_FILE = 10
    ROOK_SEMI_OPEN_FILE = 5
    QUEEN_OPEN_FILE = 5
    QUEEN_SEMI_OPEN_FILE = 3

    # global p += 1::Int
    wMaterial = 0
    bMaterial = 0
    bpawn = pawns(b, BLACK)
    wpawn = pawns(b, WHITE)
    allPawns = pawns(b)
    bpawn_squares = squares(bpawn)::Array{Square,1}
    wpawn_squares = squares(wpawn)::Array{Square,1}
    @inbounds for i in 1:1:length(wpawn_squares)
        wMaterial += 100
        score += 100  + pawn_square_table[wpawn_squares[i].val]::Int
        
        if isempty(intersect(pv.white_passed_mask[convertToHorizontalwhite[wpawn_squares[i].val]], bpawn))
            score += pawn_passed[rank(wpawn_squares[i]).val]
            #println("PASSER : ", wpawn_squares[i])
        end
        if isempty(intersect(pv.isoloni_mask[convertToHorizontalwhite[wpawn_squares[i].val]], wpawn))
            score += ISOLATED_PAWN
            #println("ISOLONI : ", wpawn_squares[i])
        end
    end
    wknights_squares = squares(knights(b, WHITE))::Array{Square,1}
    @inbounds for i in 1:1:length(wknights_squares)
        wMaterial += 320
        score += 320  + knight_square_table[wknights_squares[i].val]::Int
    end
    wbishops_squares = squares(bishops(b, WHITE))::Array{Square,1}
    @inbounds for i in 1:1:length(wbishops_squares)
        wMaterial += 330
        score += 330  + bishop_square_table[wbishops_squares[i].val]::Int
        if i == 2
            score += 30
        end
    end
    wrook_squares = squares(rooks(b, WHITE))::Array{Square,1}
    @inbounds for i in 1:1:length(wrook_squares)

        wMaterial += 500
        score += 500 + rook_square_table[wrook_squares[i].val]
        if isempty(intersect(allPawns, files[file(wrook_squares[i]).val]))
            score += ROOK_OPEN_FILE
        elseif isempty(intersect(bpawn, files[file(wrook_squares[i]).val]))
            score += ROOK_SEMI_OPEN_FILE
        end
    end
    queenWhite = queens(b, WHITE)::SquareSet
    wqueen_squares = squares(queenWhite)::Array{Square,1}
    @inbounds for i in 1:1:length(wqueen_squares)
        wMaterial += 900
        score += 900  + queen_square_table[wqueen_squares[i].val]
        if isempty(intersect(allPawns, files[file(wqueen_squares[i]).val]))
            score += QUEEN_OPEN_FILE
        elseif isempty(intersect(bpawn, files[file(wqueen_squares[i]).val]))
            score += QUEEN_SEMI_OPEN_FILE
        end
    end
    #println(score_white)
    wkings_squares = squares(kings(b, WHITE))::Array{Square,1}
    @inbounds for i in 1:1:length(wkings_squares)
        if wMaterial <= 1350
            score += 10000  + (king_endgame_square_table[wkings_squares[i].val])::Int
        else 
            # println("ENDGAME")
            score += 10000  + (king_square_table[wkings_squares[i].val])::Int
        end
    end
    @inbounds for i in 1:1:length(bpawn_squares)
        bMaterial += 100
        score -= (100 + pawn_square_table[mirror64[bpawn_squares[i].val]]::Int)
        if isempty(intersect(pv.black_passed_mask[convertToHorizontalblack[bpawn_squares[i].val]], wpawn))
            score += pawn_passed[rank(bpawn_squares[i]).val]
            #println("PASSER : ", bpawn_squares[i])
        end
        if isempty(intersect(pv.isoloni_mask[convertToHorizontalblack[bpawn_squares[i].val]], bpawn))
            score -= ISOLATED_PAWN
            #println("ISOLONI : ", bpawn_squares[i])
        end
    end
    bknights_squares = squares(knights(b, BLACK))::Array{Square,1}
    @inbounds for i in 1:1:length(bknights_squares)
        bMaterial += 320
        score -= (320 + knight_square_table[mirror64[bknights_squares[i].val]]::Int)
    end
    bbishops_squares = squares(bishops(b, BLACK))::Array{Square,1}
    @inbounds for i in 1:1:length(bbishops_squares)
        bMaterial += 330
        score -=(330  + bishop_square_table[mirror64[bbishops_squares[i].val]]::Int)
        if i == 2
            score -= 30
        end
    end
    brook_squares = squares(rooks(b, BLACK))::Array{Square,1}
    @inbounds for i in 1:1:length(brook_squares)
        bMaterial += 500
        score -= (500 + rook_square_table[mirror64[brook_squares[i].val]])
        if isempty(intersect(allPawns, files[file(brook_squares[i]).val]))
            score -= ROOK_OPEN_FILE
        elseif isempty(intersect(wpawn, files[file(brook_squares[i]).val]))
            score -= ROOK_SEMI_OPEN_FILE
        end
    end
    queenBlack = queens(b, BLACK)::SquareSet
    bqueen_squares = squares(queenBlack)::Array{Square,1}
    @inbounds for i in 1:1:length(bqueen_squares)
        bMaterial += 900
        score -= (900  + queen_square_table[mirror64[bqueen_squares[i].val]])
        if isempty(intersect(allPawns, files[file(bqueen_squares[i]).val]))
            score -= QUEEN_OPEN_FILE
        elseif isempty(intersect(wpawn, files[file(bqueen_squares[i]).val]))
            score -= QUEEN_SEMI_OPEN_FILE
        end
    end
    bkings_squares = squares(kings(b, BLACK))::Array{Square,1}
    @inbounds for i in 1:1:length(bkings_squares)
        if bMaterial <= 1350
            score -= (10000  + (king_endgame_square_table[mirror64[bkings_squares[i].val]])::Int)
        else 
            # println("ENDGAME")
            score -= (10000  + (king_square_table[mirror64[bkings_squares[i].val]])::Int)
        end
    end
    return score

end
function evaluate_board(chessboard::Board, pv::Pv)::Int
    # plus is white (except isolated pawn => because it has negative effect) and minus is black
    summe = 0
    if ismaterialdraw(chessboard)
        return 0
    end
    summe += piece_value(chessboard, pv)
    return summe
end
function big_piece(chessboard)::Bool
    if !isempty(queens(chessboard)) || !isempty(rooks(chessboard)) || !isempty(knights(chessboard))|| !isempty(bishops(chessboard))
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
        #println("Befor mirror: ", evaluate_board(chessboard))
        #println("Hashkey: ", chessboard.key)
        donullmove!(chessboard)
        after_mirror = evaluate_board(chessboard, pv)
        if after_mirror != before_mirror
            print("Not passed fen : ", fen)
        end
        #println("After mirror: ", evaluate_board(chessboard))
        #println("Hashkey: ", chessboard.key)
        donullmove!(chessboard)
    end
end

