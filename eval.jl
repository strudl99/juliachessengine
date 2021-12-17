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
    0,	0,	-10, -10, 0,0, 20, 5,
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
#m = MoveList(200)
function piece_value(b::Board, pv::Pv)::Int
    

    pWHITE = pieces(b, WHITE)
    pBLACK = pieces(b, BLACK)

    # global p += 1::Int
    bpawn = pawns(b, BLACK)
    wpawn = pawns(b, WHITE)
    allPawns = pawns(b)
    ##WHITE
    
    wpawn_squares = squares(wpawn)::Array{Square,1}
    wknights_squares = squares(knights(b, WHITE))::Array{Square,1}
    wbishops_squares = squares(bishops(b, WHITE))::Array{Square,1}
    wrook_squares = squares(rooks(b, WHITE))::Array{Square,1}
    queenWhite = queens(b, WHITE)::SquareSet
    wqueen_squares = squares(queenWhite)::Array{Square,1}
    wkings_squares = squares(kings(b, WHITE))::Array{Square,1}


    lwp = length(wpawn_squares)
    lwkn = length(wknights_squares)
    lwb = length(wbishops_squares)
    lwr = length(wrook_squares) 
    lwq = length(wqueen_squares)
    ##BLACK
    bpawn_squares = squares(bpawn)::Array{Square,1}
    bknights_squares = squares(knights(b, BLACK))::Array{Square,1}
    bbishops_squares = squares(bishops(b, BLACK))::Array{Square,1}
    brook_squares = squares(rooks(b, BLACK))::Array{Square,1}
    queenBlack = queens(b, BLACK)::SquareSet
    bqueen_squares = squares(queenBlack)::Array{Square,1}
    bkings_squares = squares(kings(b, BLACK))::Array{Square,1}

    lbp = length(bpawn_squares) 
    lbkn = length(bknights_squares)
    lbb = length(bbishops_squares)
    lbr = length(brook_squares)
    lbq = length(bqueen_squares)
    ## EVALUTAION
    TotalPhase = KnightPhase*4 + BishopPhase*4 + RookPhase*4 + QueenPhase*2
    phase = TotalPhase
    phase -= lwkn * KnightPhase
    phase -= lwb  * BishopPhase
    phase -= lwr  * RookPhase
    phase -= lwq  * QueenPhase
    phase -= lbkn * KnightPhase
    phase -= lbb  * BishopPhase
    phase -= lbr  * RookPhase
    phase -= lbq  * QueenPhase

    phase = (phase * 256 + (TotalPhase / 2)) / TotalPhase
    #print(phase)
    wMaterial = lwp * 100 + lwkn * 325 + lwb * 335 + lwr * 550 + lwq * 1000
    bMaterial = lbp * 100 + lbkn * 325 + lbb * 335 + lbr * 550 + lbq * 1000
    #println(wMaterial)
    #println(bMaterial)
    score  = wMaterial - bMaterial
    @inbounds for i in 1:1:lwp
        score += pawn_square_table[convertToHorizontal[wpawn_squares[i].val]]::Int 
        
        #score += squarecount(intersect(pawnattacks(WHITE, wpawn_squares[i]), pBLACK))
        if isempty(intersect(pv.white_passed_mask[convertToHorizontal[wpawn_squares[i].val]], bpawn))
            score += pawn_passed[rank(wpawn_squares[i]).val]
                #println(pawn_passed[rank(wpawn_squares[i]).val]) 
               # println("PASSER : ", wpawn_squares[i])
        end
         if isempty(intersect(pv.isoloni_mask[convertToHorizontal[wpawn_squares[i].val]], wpawn))
            score += ISOLATED_PAWN
            #println("ISOLONI : ", wpawn_squares[i])
        end  
    end
    
    @inbounds for i=1:1:lwkn
        score +=  knight_square_table[convertToHorizontal[wknights_squares[i].val]]::Int
        score += squarecount(knightattacks(wknights_squares[i]))
    end
    
    @inbounds for i= 1:1:lwb
        score += bishop_square_table[convertToHorizontal[wbishops_squares[i].val]]::Int
        score += squarecount(bishopattacks(pBLACK ∪ pWHITE, wbishops_squares[i])) 
    end
    
    @inbounds for i in 1:1:lwr
        score += rook_square_table[convertToHorizontal[wrook_squares[i].val]]
        score += squarecount(rookattacks(pBLACK ∪ pWHITE, wrook_squares[i]))
           if isempty(intersect(allPawns, files[file(wrook_squares[i]).val]))
            score += ROOK_OPEN_FILE
        elseif isempty(intersect(bpawn, files[file(wrook_squares[i]).val]))
            score += ROOK_SEMI_OPEN_FILE
        end  
    end
    eg_scoreWhite = score
    # old engame check: wMaterial <= 1350 || lwq == 0
    eg_scoreWhite += king_endgame_square_table[convertToHorizontal[wkings_squares[1].val]]::Int
    # score += squarecount(intersect(kingattacks(wkings_squares[1]), pBLACK))

    if wkings_squares[1] in SS_FILE_A
        if pieceon(b, file(wkings_squares[1]), SquareRank((rank(wkings_squares[1] ).val) -1 )) == PIECE_WP
            score += 5
        end
        if pieceon(b, SquareFile(file(wkings_squares[1]).val + 1), SquareRank((rank(wkings_squares[1] ).val) -1 )) == PIECE_WP
            score += 5
        end
    elseif wkings_squares[1] in SS_FILE_H
        if pieceon(b, file(wkings_squares[1]), SquareRank((rank(wkings_squares[1] ).val) -1 )) == PIECE_WP
            score += 5
        end
        if pieceon(b, SquareFile(file(wkings_squares[1]).val - 1), SquareRank((rank(wkings_squares[1] ).val) -1 )) == PIECE_WP
            score += 5
        end

    else
        if pieceon(b, file(wkings_squares[1]), SquareRank((rank(wkings_squares[1] ).val) -1 )) == PIECE_WP
            score += 5
        end
        if pieceon(b, SquareFile(file(wkings_squares[1]).val - 1), SquareRank((rank(wkings_squares[1] ).val) -1 )) == PIECE_WP
            score += 5
        end
        if pieceon(b, SquareFile(file(wkings_squares[1]).val + 1), SquareRank((rank(wkings_squares[1] ).val) -1 )) == PIECE_WP
            score += 5
        end
    end 
    score += king_square_table[convertToHorizontal[wkings_squares[1].val]]::Int
    
    eg_scoreBlack = 0
    @inbounds for i in 1:1:lbp
        score -= pawn_square_table[mirror64[convertToHorizontal[bpawn_squares[i].val]]]::Int
        eg_scoreBlack -= pawn_square_table[mirror64[convertToHorizontal[bpawn_squares[i].val]]]::Int
       # score -= squarecount(intersect(pawnattacks(BLACK, bpawn_squares[i]), pWHITE))
        if isempty(intersect(pv.black_passed_mask[mirror64[convertToHorizontal[bpawn_squares[i].val]]], wpawn))
            score -= pawn_passed_black[rank(bpawn_squares[i]).val] 
            eg_scoreBlack -= pawn_passed_black[rank(bpawn_squares[i]).val] 
            #println("PASSER : ", bpawn_squares[i])
        end
         if isempty(intersect(pv.isoloni_mask[mirror64[convertToHorizontal[bpawn_squares[i].val]]], bpawn))
            score -= ISOLATED_PAWN
            eg_scoreBlack -= ISOLATED_PAWN
            #println("ISOLONI : ", bpawn_squares[i])
        end    
    end
    
    @inbounds for i in 1:1:lbkn
        score -= knight_square_table[mirror64[convertToHorizontal[bknights_squares[i].val]]]::Int
        eg_scoreBlack -= knight_square_table[mirror64[convertToHorizontal[bknights_squares[i].val]]]::Int
        score -= squarecount(knightattacks(bknights_squares[i]))
        eg_scoreBlack -= squarecount(knightattacks(bknights_squares[i]))
    end
    
    @inbounds for i in 1:1:lbb
        score -= bishop_square_table[mirror64[convertToHorizontal[bbishops_squares[i].val]]]::Int
        eg_scoreBlack -= bishop_square_table[mirror64[convertToHorizontal[bbishops_squares[i].val]]]::Int
        score -= squarecount(bishopattacks(pBLACK ∪ pWHITE, bbishops_squares[i])) 
        eg_scoreBlack -= squarecount(bishopattacks(pBLACK ∪ pWHITE, bbishops_squares[i])) 
    end
    
    @inbounds for i in 1:1:lbr
        score -= rook_square_table[mirror64[convertToHorizontal[brook_squares[i].val]]]
        eg_scoreBlack -= rook_square_table[mirror64[convertToHorizontal[brook_squares[i].val]]]
        score -= squarecount(rookattacks(pBLACK ∪ pWHITE, brook_squares[i]))
        eg_scoreBlack -= squarecount(rookattacks(pBLACK ∪ pWHITE, brook_squares[i]))
         if isempty(intersect(allPawns, files[file(brook_squares[i]).val]))
            score -= ROOK_OPEN_FILE
            eg_scoreBlack -= ROOK_OPEN_FILE
        elseif isempty(intersect(wpawn, files[file(brook_squares[i]).val]))
            score -= ROOK_SEMI_OPEN_FILE
            eg_scoreBlack -= ROOK_SEMI_OPEN_FILE
        end   
    end
    
     # bMaterial <= 1350 || (lbq == 0)
    eg_scoreBlack -= king_endgame_square_table[mirror64[convertToHorizontal[bkings_squares[1].val]]]::Int
        #score -= squarecount(intersect(kingattacks(bkings_squares[1]), pWHITE))
    if bkings_squares[1] in SS_FILE_A
        if pieceon(b, file(bkings_squares[1]), SquareRank((rank(bkings_squares[1] ).val) + 1 )) == PIECE_BP
            score -= 5
        end
        if pieceon(b, SquareFile(file(bkings_squares[1]).val + 1), SquareRank((rank(bkings_squares[1] ).val) + 1 )) == PIECE_BP
            score -= 5
        end
    elseif bkings_squares[1] in SS_FILE_H
        if pieceon(b, file(bkings_squares[1]), SquareRank((rank(bkings_squares[1] ).val) + 1 )) == PIECE_BP
            score -= 5
        end
        if pieceon(b, SquareFile(file(bkings_squares[1]).val - 1), SquareRank((rank(bkings_squares[1] ).val) + 1 )) == PIECE_BP
            score -= 5
        end

    else
        if pieceon(b, file(bkings_squares[1]), SquareRank((rank(bkings_squares[1] ).val) + 1 )) == PIECE_BP
            score -= 5
        end
        if pieceon(b, SquareFile(file(bkings_squares[1]).val - 1), SquareRank((rank(bkings_squares[1] ).val) + 1 )) == PIECE_BP
            score -= 5
        end
        if pieceon(b, SquareFile(file(bkings_squares[1]).val + 1), SquareRank((rank(bkings_squares[1] ).val) + 1 )) == PIECE_BP
            score -= 5
        end
    end 
    score -= king_square_table[mirror64[convertToHorizontal[bkings_squares[1].val]]]::Int
    #score -= squarecount(intersect(kingattacks(bkings_squares[1]), pWHITE))
    
    
    if lbb >= 2
        score -= 30
        eg_scoreBlack -= 30
    end
    if lwb >= 2
        score += 30
        eg_scoreWhite += 30
    end

    eg_score = eg_scoreWhite + eg_scoreBlack
    result = (score * (256 - phase) + eg_score * phase) / 256
    #println(score)
    #println(eg_score)
    #println(result)
    if sidetomove(b) == WHITE
        #score += (movecount(b))
        return convert(Int64, round(result, digits=0))
    else
        #score -= (movecount(b))
        return -convert(Int64, round(result, digits=0))
    end 
end
function evaluate_board(chessboard::Board, pv::Pv)::Int
    # plus is white (except isolated pawn => because it has negative effect) and minus is black
    summe = piece_value(chessboard, pv)
    return summe
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

