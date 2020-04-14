using Chess, Chess.Book
using Random
include("movegen.jl")

MATE = 1e5
DRAW = 0
files = [SS_FILE_A, SS_FILE_B, SS_FILE_C, SS_FILE_D, SS_FILE_E, SS_FILE_F, SS_FILE_G, SS_FILE_H]
ranks = [SS_RANK_1, SS_RANK_2, SS_RANK_3, SS_RANK_4, SS_RANK_5, SS_RANK_6, SS_RANK_7, SS_RANK_8]
black_passed_mask = []
white_passed_mask = []
isolated_passed_mask = zeros(UInt, 64)
const pawn_passed = [0, 5, 10, 20, 35, 50, 100, 200]
const pawn_square_table = [
    [0, 0, 0, 0, 0, 0, 0, 0],
    [5, 10, 10, -20, -20, 10, 10, 5],
    [5, -5, -10, 0, 0, -10, -5, 5],
    [0, 0, 0, 20, 20, 0, 0, 0],
    [5, 5, 10, 25, 25, 10, 5, 5],
    [10, 10, 20, 30, 30, 20, 10, 10],
    [50, 50, 50, 50, 50, 50, 50, 50],
    [0, 0, 0, 0, 0, 0, 0, 0]
]

const knight_square_table = [
[-50,-40,-30,-30,-30,-30,-40,-50],
[-40,-20,  0,  5,  5,  0,-20,-40],
[-30,  5, 10, 15, 15, 10,  5,-30],
[-30,  0, 15, 20, 20, 15,  0,-30],
[    -30,  5, 15, 20, 20, 15,  5,-30],
[    -30,  0, 10, 15, 15, 10,  0,-30],
[    -40,-20,  0,  0,  0,  0,-20,-40],
[    -50,-40,-30,-30,-30,-30,-40,-50]
]

const bishop_square_table = [
    [-20,-10,-10,-10,-10,-10,-10,-20],
    [-10,  0,  0,  0,  0,  0,  0,-10],
    [-10,  0,  5, 10, 10,  5,  0,-10],
    [-10,  5,  5, 10, 10,  5,  5,-10],
    [-10,  0, 10, 10, 10, 10,  0,-10],
    [-10, 10, 10, 10, 10, 10, 10,-10],
    [-10,  5,  0,  0,  0,  0,  5,-10],
    [-20,-10,-10,-10,-10,-10,-10,-20],
    ]

const rook_square_table = [
     [0,  0,  0,  0,  0,  0,  0,  0],
    [5,  10,  10,  10,  10,  10,  10, 5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
     [-5, 0, 0, 0, 0, 0, 0,  -5],
     [0,  0,  0,  5,  5,  0,  0,  0]
    ]

const queen_square_table = [
    [-20, -10, -10, -5, -5, -10, -10, -20,],
    [-10, 0, 0, 0, 0, 0, 0, -10],
    [10, 0, 5, 5, 5, 5, 0, -10],
    [-5, 0, 5, 5, 5, 5, 0, -5],
    [0, 0, 5, 5, 5, 5, 0, -5],
    [-10, 5, 5, 5, 5, 5, 0, -10],
    [-10, 0, 5, 0, 0, 0, 0, -10],
    [-20, -10, -10, -5, -5, -10, -10, -20]]

const king_square_table = 
[[-30, -40, -40, -50, -50, -40, -40, -30],
[-30, -40, -40, -50, -50, -40, -40, -30],
[-30, -40, -40, -50, -50, -40, -40, -30],
[-30, -40, -40, -50, -50, -40, -40, -30],
[-20, -30, -30, -40, -40, -30, -30, -20],
[-10, -20, -20, -20, -20, -20, -20, -10],
[20, 20, 0, 0, 0, 0, 20, 20],
[20, 30, 10, 0, 0, 10, 30, 20]]

const king_endgame_square_table = [
[-50,-40,-30,-20,-20,-30,-40,-50],
[-30,-20,-10,  0,  0,-10,-20,-30],
[-30,-10, 20, 30, 30, 20,-10,-30],
[-30,-10, 30, 40, 40, 30,-10,-30],
[-30,-10, 30, 40, 40, 30,-10,-30],
[-30,-10, 20, 30, 30, 20,-10,-30],
[-30,-30,  0,  0,  0,  0,-30,-30],
[-50,-30,-30,-30,-30,-30,-30,-50]]

endgame = false


function convert_square(square::Int, is_white::Bool)
    square -= 1
    row = !is_white ? 7 - (square ÷ 8) : square ÷ 8
    column = square % 8 
    return (row + 1, column + 1)
end

function init_eval_masks()
    for i in 1:1:64
        push!(white_passed_mask, SS_EMPTY)
        push!(black_passed_mask, SS_EMPTY)
    end

     #=    tsq = i - 7
        while tsq > 0
            black_passed_mask[i] |= (1 << tsq)
            tsq -= 1
        end =#
    # end
end
#= function double_pawns(chessboard)
    a = b = c = d = e = f = g = h = 0
    temp = 2
    pwn = sidetomove(chessboard) == WHITE ? PIECE_WP : PIECE_BP
    db_W = false
    db_B = false
    prev_a = prev_b = prev_c = prev_d = prev_e = prev_f = prev_g = prev_h = 0
    for i in range(1, stop = 8, step = 1)

            
        if pieceon(chessboard, FILE_A, rank(Square(i))) == PIECE_WP 
            a += 1
            if a >= temp
                db_W = true
                break
            end

            
                
        end
        if pieceon(chessboard, FILE_B, rank(Square(i))) == PIECE_WP 
            
            b += 1
            if b >=  temp
                db_W = true
                break
            end

                
        end
        if pieceon(chessboard, FILE_C, rank(Square(i))) == PIECE_WP 
            if c >= temp
                db_W = true
                break
            end
                
        end
        if pieceon(chessboard, FILE_D, rank(Square(i))) == PIECE_WP 
            d += 1
            if d >=  temp
                db_W = true
                break
            end

                
        end
        if pieceon(chessboard, FILE_E, rank(Square(i))) == PIECE_WP
            e += 1
            if e >=  temp
                db_W = true
                break
            end

                
        end
        if pieceon(chessboard, FILE_F, rank(Square(i))) == PIECE_WP 
            f += 1
            if f >= temp
                db_W = true
                break
            end
 
                
        end
        if pieceon(chessboard, FILE_G, rank(Square(i))) == PIECE_WP 
            if g >=  temp
                db_W = true
                break
            end

                
        end
        if pieceon(chessboard, FILE_H, rank(Square(i))) == PIECE_WP 
            h += 1
            if h >= temp
                db_W = true
                break
            end
                
        end
        if pieceon(chessboard, FILE_A, rank(Square(i))) == PIECE_BP
            prev_a += 1
            if prev_a >= temp
                db_B = true
                break
            end

            
                
        end
        if pieceon(chessboard, FILE_B, rank(Square(i))) == PIECE_BP
            prev_b += 1
            if prev_b >=  temp
                db_B = true
                break
            end

                
        end
        if pieceon(chessboard, FILE_C, rank(Square(i))) == PIECE_BP
            prev_c += 1
            if prev_c >= temp
                db_B = true
                break
            end
                
        end
        if  pieceon(chessboard, FILE_D, rank(Square(i))) == PIECE_BP
            prev_d += 1
            if prev_d >=  temp
                db_B = true
                break
            end

                
        end
        if pieceon(chessboard, FILE_E, rank(Square(i))) == PIECE_BP
            prev_e += 1
            if prev_e >=  temp
                db_B = true
                break
            end

                
        end
        if  pieceon(chessboard, FILE_F, rank(Square(i))) == PIECE_BP
            prev_f += 1
            if prev_f >= temp
                db_B = true
                break
            end
 
                
        end
        if  pieceon(chessboard, FILE_G, rank(Square(i))) == PIECE_BP
            prev_g += 1
            if prev_g >=  temp
                db_B = true
                break
            end

                
        end
        if  pieceon(chessboard, FILE_H, rank(Square(i))) == PIECE_BP
            prev_h += 1
            if prev_h >= temp
                db_B = true
                break
            end
                
        end
    end
  
    return (db_W, db_B)
end =#

# function that calculate the piece value of the board + the value of the square table 
#= 
function piece_value(piece, square,  chessboard)
    score = 0
    row_black = convert_square(square, false)[1]
    column_black = convert_square(square, false)[2]
    row_white = convert_square(square, true)[1]
    column_white = convert_square(square, true)[2]
    if piece == PIECE_WP
        if endgame == false
            score += 100  + pawn_square_table[row_white][column_white]
        end
    end
    if piece == PIECE_WN
        score += 320  + knight_square_table[row_white][column_white]
    end
    if piece == PIECE_WB
        score += 330  + bishop_square_table[row_white][column_white]
    end
    if piece == PIECE_WR
        score += 500 + rook_square_table[row_white][column_white] + rook_open_file(chessboard)[1]
    end
    if piece == PIECE_WQ
        score += 900  + queen_square_table[row_white][column_white] + queen_open_file(chessboard)[1]
    end
    if piece == PIECE_WK
        if endgame == false
            score += 10000 + king_square_table[row_white][column_white]
        else
            score += 10000  + (king_endgame_square_table[row_white][column_white])
        end
    end
    if piece == PIECE_BP
        if endgame == false
            score += -100 - (pawn_square_table[row_black][column_black] )
        end
    end
    if piece == PIECE_BN
        score += -320 - (knight_square_table[row_black][column_black] )
    end
    if piece == PIECE_BB
        score += -330 - (bishop_square_table[row_black][column_black] ) 
    end
    if piece == PIECE_BR
        score += -500 - (rook_square_table[row_black][column_black] ) - rook_open_file(chessboard)[2]
    end
    if piece == PIECE_BQ
        score += -900 - (queen_square_table[row_black][column_black]) - queen_open_file(chessboard)[2]
    end
    if piece == PIECE_BK
        if endgame == false
            score += -10000  - (king_square_table[row_black][column_black])
        else 
            score += -10000  - (king_endgame_square_table[row_black][column_black])
        end
    end
    return score

end =#
all = 0
p = 0

function piece_value(b::Board)::Int
    score = 0

    global p += 1
    wpawn_squares = squares(pawns(b, WHITE))
    for i in 1:1:length(wpawn_squares)
        row_white = convert_square(wpawn_squares[i].val, true)[1]
        column_white = convert_square(wpawn_squares[i].val, true)[2]
        score += 100  + pawn_square_table[row_white][column_white]
    end
    wknights_squares = squares(knights(b, WHITE))
    for i in 1:1:length(wknights_squares)
        row_white = convert_square(wknights_squares[i].val, true)[1]
        column_white = convert_square(wknights_squares[i].val, true)[2]
        score += 320  + knight_square_table[row_white][column_white]
    end
    wbishops_squares = squares(bishops(b, WHITE))
    for i in 1:1:length(wbishops_squares)
        row_white = convert_square(wbishops_squares[i].val, true)[1]
        column_white = convert_square(wbishops_squares[i].val, true)[2]
        score += 330  + bishop_square_table[row_white][column_white]
    end
    wrook_squares = squares(rooks(b, WHITE))
    for i in 1:1:length(wrook_squares)
        row_white = convert_square(wrook_squares[i].val, true)[1]
        column_white = convert_square(wrook_squares[i].val, true)[2]
        score += 500 + rook_square_table[row_white][column_white] + rook_open_file(b)[1]
    end
    wqueen_squares = squares(queens(b, WHITE))
    for i in 1:1:length(wqueen_squares)
        row_white = convert_square(wqueen_squares[i].val, true)[1]
        column_white = convert_square(wqueen_squares[i].val, true)[2]
        score += 900  + queen_square_table[row_white][column_white] + queen_open_file(b)[1]
    end
    wkings_squares = squares(kings(b, WHITE))
    for i in 1:1:length(wkings_squares)
        row_white = convert_square(wkings_squares[i].val, true)[1]
        column_white = convert_square(wkings_squares[i].val, true)[2]
        if endgame == false
            score += 10000  + (king_square_table[row_white][column_white])
        else 
            score += 10000  + (king_endgame_square_table[row_white][row_white])
        end
    end
    if score <= 11360
        global endgame = true
    end
    bpawn_squares = squares(pawns(b, BLACK))
    for i in 1:1:length(bpawn_squares)
        row_white = convert_square(bpawn_squares[i].val, false)[1]
        column_white = convert_square(bpawn_squares[i].val, false)[2]
        score -= 100  + pawn_square_table[row_white][column_white]
    end
    bknights_squares = squares(knights(b, BLACK))
    for i in 1:1:length(bknights_squares)
        row_white = convert_square(bknights_squares[i].val, false)[1]
        column_white = convert_square(bknights_squares[i].val, false)[2]
        score -= 320  + knight_square_table[row_white][column_white]
    end
    bbishops_squares = squares(bishops(b, BLACK))
    for i in 1:1:length(bbishops_squares)
        row_white = convert_square(bbishops_squares[i].val, false)[1]
        column_white = convert_square(bbishops_squares[i].val, false)[2]
        score -= 330  + bishop_square_table[row_white][column_white]
    end
    brook_squares = squares(rooks(b, BLACK))
    for i in 1:1:length(brook_squares)
        row_white = convert_square(brook_squares[i].val, false)[1]
        column_white = convert_square(brook_squares[i].val, false)[2]
        score -= 500 + rook_square_table[row_white][column_white] + rook_open_file(b)[1]
    end
    bqueen_squares = squares(queens(b, BLACK))
    for i in 1:1:length(bqueen_squares)
        row_white = convert_square(bqueen_squares[i].val, false)[1]
        column_white = convert_square(bqueen_squares[i].val, false)[2]
        score -= 900  + queen_square_table[row_white][column_white] + queen_open_file(b)[1]
    end
    bkings_squares = squares(kings(b, BLACK))
    for i in 1:1:length(bkings_squares)
        row_black = convert_square(bkings_squares[i].val, false)[1]
        column_black = convert_square(bkings_squares[i].val, false)[2]
        if endgame == false
            score -= 10000  + (king_square_table[row_black][column_black])
        else 
            score -= 10000  + (king_endgame_square_table[row_black][column_black])
        end
    end
    return score

end

function rook_open_file(b::Board)
    white = 0
    black = 0
    for i in files
        if isempty(intersect(pawns(b, WHITE), i)) && !isempty(intersect(rooks(b, WHITE), i))
            white = 5
        end
        if isempty(intersect(pawns(b, BLACK), i)) && !isempty(intersect(rooks(b, BLACK), i))
            black = 5
        end
        if isempty(intersect(pawns(b), i)) && !isempty(intersect(rooks(b, BLACK), i))
            black = 10
        end
        if isempty(intersect(pawns(b), i)) && !isempty(intersect(rooks(b, WHITE), i))
            white = 10
        end
    end

        

    return (white, black)
end 

function queen_open_file(b::Board)
    white = 0
    black = 0
    for i in files
        if isempty(intersect(pawns(b, WHITE), i)) && !isempty(intersect(queens(b, WHITE), i))
            white = 5
        end
        if isempty(intersect(pawns(b, BLACK), i)) && !isempty(intersect(queens(b, BLACK), i))
            black = 5
        end
        if isempty(intersect(pawns(b), i)) && !isempty(intersect(queens(b, BLACK), i))
            black = 10
        end
        if isempty(intersect(pawns(b), i)) && !isempty(intersect(queens(b, WHITE), i))
            white = 10
        end
    end

    return (white, black)
end

function double_bishops(chessboard::Board)
    bb_count = 0
    bw_count = 0
    sum = 0
    for i in range(1, stop = 64, step = 1)
        if pieceon(chessboard, Square(i)) == PIECE_BB
            bb_count += 1
        end
        if pieceon(chessboard, Square(i)) == PIECE_WB
            bw_count += 1
        end
    end
    return bb_count, bw_count
end

function evaluate_board(chessboard::Board)::Int
    
    
    summe = 0
    side = sidetomove(chessboard) == WHITE ? 1 : -1

    summe += piece_value(chessboard)
    if double_bishops(chessboard)[1] == 2
        summe -= 30
    end
    if double_bishops(chessboard)[2] == 2
        summe += 30
    end
 #=    if double_pawns(chessboard)[1]
        summe -= 10
    end
    if double_pawns(chessboard)[2]
        summe += 10
    end =#
    return summe
end

function big_piece(chessboard)::Bool
    for i in 1:1:64
        if pieceon(chessboard, Square(i)) != EMPTY && pieceon(chessboard, Square(i)) != PIECE_WP &&  pieceon(chessboard, Square(i)) != PIECE_BP  && pieceon(chessboard, Square(i)) != PIECE_WK &&  pieceon(chessboard, Square(i)) != PIECE_BK
            return true
        end
    end
    return false
end



function mirror(chessboard)
    println("Befor mirror: ", evaluate_board(chessboard))
    println("Hashkey: ", generate_pos_key(chessboard))
    donullmove!(chessboard)
    println("After mirror: ", evaluate_board(chessboard))
    println("Hashkey: ", generate_pos_key(chessboard))
    donullmove!(chessboard)
end

