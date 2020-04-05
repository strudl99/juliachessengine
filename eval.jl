using Chess, Chess.Book

const pawn_square_table = [
     [0,  0,  0,  0,  0,  0,  0,  0],
     [5, 10, 10,-20,-20, 10, 10,  5],
     [5, -5,-10,  0,  0,-10, -5,  5],
     [0,  0,  0, 20, 20,  0,  0,  0],
     [5,  5, 10, 25, 25, 10,  5,  5],
    [10, 10, 20, 30, 30, 20, 10, 10],
    [50, 50, 50, 50, 50, 50, 50, 50],
     [0,  0,  0,  0,  0,  0,  0,  0]
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
    [-10,  5,  0,  0,  0,  0,  5,-10],
    [-10, 10, 10, 10, 10, 10, 10,-10],
    [-10,  0, 10, 10, 10, 10,  0,-10],
    [-10,  5,  5, 10, 10,  5,  5,-10],
    [-10,  0,  5, 10, 10,  5,  0,-10],
    [-10,  0,  0,  0,  0,  0,  0,-10],
    [-20,-10,-10,-10,-10,-10,-10,-20]
    ]

const rook_square_table = [
     [0,  0,  0,  5,  5,  0,  0,  0],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
     [5, 10, 10, 10, 10, 10, 10,  5],
     [0,  0,  0,  0,  0,  0,  0,  0]
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
function convert_square(square, is_white)
    square -= 1
    row = !is_white ? 7 - (square ÷ 8) : square ÷ 8
    column = square % 8 
    return (row + 1, column + 1)
end

function double_pawns(chessboard)
    a = b = c = d = e = f = g = h = 0
    pwn = sidetomove(chessboard) == WHITE ? PIECE_WP : PIECE_BP
    db = false
    prev_a = prev_b = prev_c = prev_d = prev_e = prev_f = prev_g = prev_h = 1e8
    for i in range(2, stop = 7, step = 1)

            
        if pieceon(chessboard, FILE_A, rank(Square(i))) == pwn
                
            if prev_a == i - 1
                db = true
                break
            end
            prev_a = i
            a += 1
                
        end
        if pieceon(chessboard, FILE_B, rank(Square(i))) == pwn
            b += 1
            if prev_b == i - 1
                db = true
                break
            end
            prev_b = i
                
        end
        if pieceon(chessboard, FILE_C, rank(Square(i))) == pwn
            c += 1
            if prev_c == i - 1
                db = true
                break
            end
            prev_c = i
                
        end
        if pieceon(chessboard, FILE_D, rank(Square(i))) == pwn
            d += 1
            if prev_d == i - 1
                db = true
                break
            end
            prev_d = i
                
        end
        if pieceon(chessboard, FILE_E, rank(Square(i))) == pwn
            e += 1
            if prev_e == i - 1
                db = true
                break
            end
            prev_e = i
                
        end
        if pieceon(chessboard, FILE_F, rank(Square(i))) == pwn
            f += 1
            if prev_f == i - 1
                db = true
                break
            end
            prev_f = i
                
        end
        if pieceon(chessboard, FILE_G, rank(Square(i))) == pwn
            g += 1
            if prev_g == i - 1
                db = true
                break
            end
            prev_g = i
                
        end
        if pieceon(chessboard, FILE_H, rank(Square(i))) == pwn
            h += 1
            if prev_h == i - 1
                db = true
                break
            end
            prev_h = i
                
        end
        
        
    end
    if db == true
        return -10
    else
        return 0
    end

end

# function that calculate the piece value of the board + the value of the square table 

function piece_value(piece, square,  chessboard)
    score = 0
    row_black = convert_square(square, false)[1]
    column_black = convert_square(square, false)[2]
    row_white = convert_square(square, true)[1]
    column_white = convert_square(square, true)[2]
    if piece == Piece(WHITE, PAWN)
        score += 100  + pawn_square_table[row_white][column_white]   + double_pawns(chessboard)
    end
    if piece == Piece(WHITE, KNIGHT)
        score += 350  + knight_square_table[row_white][column_white]
    end
    if piece == Piece(WHITE, BISHOP)
        score += 400  + bishop_square_table[row_white][column_white]
    end
    if piece == Piece(WHITE, ROOK)
        score += 500 + rook_square_table[row_white][column_white]  + rook_open_file(chessboard)
    end
    if piece == Piece(WHITE, QUEEN)
        score += 900  + queen_square_table[row_white][column_white]
    end
    if piece == Piece(WHITE, KING)
        if endgame == false
            score += 10000 + king_square_table[row_white][column_white]
        else
            score += 10000  + (king_endgame_square_table[row_white][column_white])
        end
    end
    if piece == Piece(BLACK, PAWN)
        score += -100 - (pawn_square_table[row_black][column_black] ) - double_pawns(chessboard)
    end
    if piece == Piece(BLACK, KNIGHT)
        score += -350 - (knight_square_table[row_black][column_black] )
    end
    if piece == Piece(BLACK, BISHOP)
        score += -400 - (bishop_square_table[row_black][column_black] ) 
    end
    if piece == Piece(BLACK, ROOK)
        score += -500 - (rook_square_table[row_black][column_black] )  - rook_open_file(chessboard)
    end
    if piece == Piece(BLACK, QUEEN)
        score += -900 - (queen_square_table[row_black][column_black])
    end
    if piece == Piece(BLACK, KING)
        if endgame == false
            score += -10000  - (king_square_table[row_black][column_black])
        else 
            score += -10000  - (king_endgame_square_table[row_black][column_black])
        end
    end
    return score

end

function rook_open_file(chessboard)
    e = emptysquares(chessboard)
    if e == SS_FILE_A || e == SS_FILE_B || e ==  SS_FILE_C || e == SS_FILE_D || e == SS_FILE_E || e == SS_FILE_F || e == SS_FILE_G || e == SS_FILE_H
        return 10
    else 
        return 0
    end
end

function double_bishops(chessboard)
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

function evaluate_board(chessboard)
    number_of_pieces = count_pieces(chessboard)
    if number_of_pieces < 12
       	global endgame = true
    end
    summe = 0
    side = sidetomove(chessboard)
    for square in range(1, stop = 64, step = 1)
        summe += piece_value(pieceon(chessboard, Square(square)), square, chessboard)
        i = square
    end
    if double_bishops(chessboard)[1] == 2
        summe -= 30
    elseif double_bishops(chessboard)[2] == 2
        summe += 30
    end
    if endgame == true
       	if ischeck(chessboard)
        	   summe += 100 
       	end

    end
    return summe
end

function sort_moves(chessboard)

    all_moves = moves(chessboard)
    isort = []
    r = false
    if sidetomove(chessboard) == WHITE
        r = false
    else
        r = true
    end
    for move in all_moves
        u = domove!(chessboard, move)
        push!(isort, (evaluate_board(chessboard), move))
        undomove!(chessboard, u)
    end
    all_moves = last.(sort!(isort, lt = (x, y)->(x[1] > y[1]), rev = r))
    return all_moves
end

function count_pieces(chessboard)
    piece_count_prev = 0
    for square in range(1, stop = 64, step = 1)
        if pieceon(chessboard, Square(square)) != EMPTY
            piece_count_prev += 1
        end
    end
    return piece_count_prev
end

function capture_moves(chessboard)
    capture_moves = []
    prev = count_pieces(chessboard)
    all_moves = moves(chessboard)
    for move in all_moves
        u = domove!(chessboard, move)
        current = count_pieces(chessboard)
        if current != prev
            push!(capture_moves, move)
        end
        undomove!(chessboard, u)
    end
    return capture_moves

end



