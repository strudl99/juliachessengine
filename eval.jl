using Chess, Chess.Book
using Random
include("movegen.jl")



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

endgame = false::Bool


function convert_square(square::Int, is_white::Bool)::Tuple
    square -= 1
    row = !is_white ? 7 - (square ÷ 8) : square ÷ 8
    column = square % 8 
    return (row + 1, column + 1)
end

function piece_value(b::Board)::Int

    score = 0::Int
    endgame = false
    # global p += 1::Int
    wpawn_squares = squares(pawns(b, WHITE))::Array{Square,1}
    @inbounds for i in 1:1:length(wpawn_squares)
        row_white = convert_square(wpawn_squares[i].val, true)[1]::Int
        column_white = convert_square(wpawn_squares[i].val, true)[2]::Int
        score += 100  + pawn_square_table[row_white][column_white]::Int # - isolated_pawn(b)[1]
    end
    wknights_squares = squares(knights(b, WHITE))::Array{Square,1}
    @inbounds for i in 1:1:length(wknights_squares)
        row_white = convert_square(wknights_squares[i].val, true)[1]::Int
        column_white = convert_square(wknights_squares[i].val, true)[2]::Int
        score += 320  + knight_square_table[row_white][column_white]::Int
    end
    wbishops_squares = squares(bishops(b, WHITE))::Array{Square,1}
    @inbounds for i in 1:1:length(wbishops_squares)
        row_white = convert_square(wbishops_squares[i].val, true)[1]::Int
        column_white = convert_square(wbishops_squares[i].val, true)[2]::Int
        score += 330  + bishop_square_table[row_white][column_white]::Int
    end
    wrook_squares = squares(rooks(b, WHITE))::Array{Square,1}
    @inbounds for i in 1:1:length(wrook_squares)
        row_white = convert_square(wrook_squares[i].val, true)[1]::Int
        column_white = convert_square(wrook_squares[i].val, true)[2]::Int
        score += 500 + rook_square_table[row_white][column_white] + rook_open_file(b)[1]::Int
    end
    wqueen_squares = squares(queens(b, WHITE))::Array{Square,1}
    @inbounds for i in 1:1:length(wqueen_squares)
        row_white = convert_square(wqueen_squares[i].val, true)[1]::Int
        column_white = convert_square(wqueen_squares[i].val, true)[2]::Int
        score += 900  + queen_square_table[row_white][column_white] + queen_open_file(b)[1]::Int
    end
    score_white = score
    # println(score_white)
    wkings_squares = squares(kings(b, WHITE))::Array{Square,1}
    @inbounds for i in 1:1:length(wkings_squares)
        row_white = convert_square(wkings_squares[i].val, true)[1]::Int
        column_white = convert_square(wkings_squares[i].val, true)[2]::Int
        if score_white <= 1360
            score += 10000  + (king_endgame_square_table[row_white][row_white])::Int
        else 
            # println("ENDGAME")
            score += 10000  + (king_square_table[row_white][column_white])::Int
        end
    end
    bpawn_squares = squares(pawns(b, BLACK))::Array{Square,1}
    @inbounds for i in 1:1:length(bpawn_squares)
        row_white = convert_square(bpawn_squares[i].val, false)[1]::Int
        column_white = convert_square(bpawn_squares[i].val, false)[2]::Int
        score -= 100  + pawn_square_table[row_white][column_white]::Int #+ isolated_pawn(b)[2]
    end
    bknights_squares = squares(knights(b, BLACK))::Array{Square,1}
    @inbounds for i in 1:1:length(bknights_squares)
        row_white = convert_square(bknights_squares[i].val, false)[1]::Int
        column_white = convert_square(bknights_squares[i].val, false)[2]::Int
        score -= 320  + knight_square_table[row_white][column_white]::Int
    end
    bbishops_squares = squares(bishops(b, BLACK))::Array{Square,1}
    @inbounds for i in 1:1:length(bbishops_squares)
        row_white = convert_square(bbishops_squares[i].val, false)[1]::Int
        column_white = convert_square(bbishops_squares[i].val, false)[2]::Int
        score -= 330  + bishop_square_table[row_white][column_white]::Int
    end
    brook_squares = squares(rooks(b, BLACK))::Array{Square,1}
    @inbounds for i in 1:1:length(brook_squares)
        row_white = convert_square(brook_squares[i].val, false)[1]::Int
        column_white = convert_square(brook_squares[i].val, false)[2]::Int
        score -= 500 + rook_square_table[row_white][column_white] + rook_open_file(b)[1]::Int
    end
    bqueen_squares = squares(queens(b, BLACK))::Array{Square,1}
    @inbounds for i in 1:1:length(bqueen_squares)
        row_white = convert_square(bqueen_squares[i].val, false)[1]::Int
        column_white = convert_square(bqueen_squares[i].val, false)[2]::Int
        score -= 900  + queen_square_table[row_white][column_white] + queen_open_file(b)[1]::Int
    end
    bkings_squares = squares(kings(b, BLACK))::Array{Square,1}
    @inbounds for i in 1:1:length(bkings_squares)
        row_black = convert_square(bkings_squares[i].val, false)[1]::Int
        column_black = convert_square(bkings_squares[i].val, false)[2]::Int
        if score_white <= 1360
            score -= 10000  + (king_endgame_square_table[row_black][column_black])::Int
        else 
            # println("ENDGAME")
            score -= 10000  + (king_square_table[row_black][column_black])::Int
        end
    end
    return score

end

function rook_open_file(b::Board)::Tuple
    files = [SS_FILE_A, SS_FILE_B, SS_FILE_C, SS_FILE_D, SS_FILE_E, SS_FILE_F, SS_FILE_G, SS_FILE_H]
    white = 0::Int
    black = 0::Int
    @inbounds for i in files
        if isempty(intersect(pawns(b, WHITE), i)) && !isempty(intersect(rooks(b, WHITE), i))
            white = 5::Int
        end
        if isempty(intersect(pawns(b, BLACK), i)) && !isempty(intersect(rooks(b, BLACK), i))
            black = 5::Int
        end
        if isempty(intersect(pawns(b), i)) && !isempty(intersect(rooks(b, BLACK), i))
            black = 10::Int
        end
        if isempty(intersect(pawns(b), i)) && !isempty(intersect(rooks(b, WHITE), i))
            white = 10::Int
        end
    end

        

    return (white, black)
end 
# TODO: only to rank of pawn check
function isolated_pawn(b::Board)::Tuple
    files = [SS_FILE_A, SS_FILE_B, SS_FILE_C, SS_FILE_D, SS_FILE_E, SS_FILE_F, SS_FILE_G, SS_FILE_H]
    white = 0::Int
    black = 0::Int
    @inbounds for i = 1:1:length(files)
        if i >= 2 && i <= 7
            if isempty(intersect(pawns(b, WHITE), files[i - 1])) && isempty(intersect(pawns(b, WHITE), files[i + 1])) && !isempty(intersect(pawns(b, WHITE), files[i]))
                white = 15::Int
            end
            if isempty(intersect(pawns(b, BLACK), files[i - 1])) && isempty(intersect(pawns(b, WHITE), files[i + 1])) && !isempty(intersect(pawns(b, WHITE), files[i]))
                black = 15::Int
            end
        end

    end
    return white, black
end

function queen_open_file(b::Board)::Tuple
    files = [SS_FILE_A, SS_FILE_B, SS_FILE_C, SS_FILE_D, SS_FILE_E, SS_FILE_F, SS_FILE_G, SS_FILE_H]
    white = 0::Int
    black = 0::Int
    @inbounds for i in files
        if isempty(intersect(pawns(b, WHITE), i)) && !isempty(intersect(queens(b, WHITE), i))
            white = 5::Int
        end
        if isempty(intersect(pawns(b, BLACK), i)) && !isempty(intersect(queens(b, BLACK), i))
            black = 5::Int
        end
        if isempty(intersect(pawns(b), i)) && !isempty(intersect(queens(b, BLACK), i))
            black = 10::Int
        end
        if isempty(intersect(pawns(b), i)) && !isempty(intersect(queens(b, WHITE), i))
            white = 10::Int
        end
    end

    return (white, black)
end

function double_bishops(chessboard::Board)::Tuple
    bb_count = 0
    bw_count = 0
    sum = 0
    @inbounds for i in range(1, stop = 64, step = 1)
        if pieceon(chessboard, Square(i)) == PIECE_BB
            bb_count += 1
        end
        if pieceon(chessboard, Square(i)) == PIECE_WB
            bw_count += 1
        end
    end
    return (bb_count, bw_count)
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
    return summe
end

function big_piece(chessboard)::Bool
    @inbounds for i in 1:1:64
        if pieceon(chessboard, Square(i)) != EMPTY && pieceon(chessboard, Square(i)) != PIECE_WP &&  pieceon(chessboard, Square(i)) != PIECE_BP  && pieceon(chessboard, Square(i)) != PIECE_WK &&  pieceon(chessboard, Square(i)) != PIECE_BK
            return true
        end
    end
    return false
end

function mirror(chessboard)
    println("Befor mirror: ", evaluate_board(chessboard))
    println("Hashkey: ", chessboard.key)
    donullmove!(chessboard)
    println("After mirror: ", evaluate_board(chessboard))
    println("Hashkey: ", chessboard.key)
    donullmove!(chessboard)
end

