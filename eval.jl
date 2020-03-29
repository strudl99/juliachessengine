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

const king_square_table =  [-30, -40, -40, -50, -50, -40, -40, -30],
[-30, -40, -40, -50, -50, -40, -40, -30],
[-30, -40, -40, -50, -50, -40, -40, -30],
[-30, -40, -40, -50, -50, -40, -40, -30],
[-20, -30, -30, -40, -40, -30, -30, -20],
[-10, -20, -20, -20, -20, -20, -20, -10],
[20, 20, 0, 0, 0, 0, 20, 20],
[20, 30, 10, 0, 0, 10, 30, 20]


function random(chessboard)
    
    all_moves = moves(chessboard)
    checkmoves = filter(m->ischeck(domove(chessboard, m)), all_moves)
    if !isempty(checkmoves)
        move = rand(checkmoves)
    else
        move = rand(all_moves)
    end
        
        # println(b)
    return move
        
end

function convert_square(square, is_white)
    square -= 1
    row = !is_white ? 7 - (square ÷ 8) : square ÷ 8
    column = square % 8 
    return (row + 1, column + 1)
end
function piece_value(piece, square,  chessboard)
    score = 0
    row_black = convert_square(square, false)[1]
    column_black = convert_square(square, false)[2]

    row_white = convert_square(square, true)[1]
    column_white = convert_square(square, true)[2]
    if piece == Piece(WHITE, PAWN)
        score += 100 + pawn_square_table[row_white][column_white]
    end
    if piece == Piece(WHITE, KNIGHT)
        score += 300 + knight_square_table[row_white][column_white]
    end
    if piece == Piece(WHITE, BISHOP)
        score += 300 + bishop_square_table[row_white][column_white]
    end
    if piece == Piece(WHITE, ROOK)
        score += 500 + rook_square_table[row_white][column_white]
    end
    if piece == Piece(WHITE, QUEEN)
        score += 900 + queen_square_table[row_white][column_white]
    end
    if piece == Piece(WHITE, KING)
        score += 10000000 + king_square_table[row_white][column_white]
    end
    if piece == Piece(BLACK, PAWN)
        score += -100 + pawn_square_table[row_black][column_black]
    end
    if piece == Piece(BLACK, KNIGHT)
        score += -300 + knight_square_table[row_black][column_black]
    end
    if piece == Piece(BLACK, BISHOP)
        score += -300 + bishop_square_table[row_black][column_black]
    end
    if piece == Piece(BLACK, ROOK)
        score += -500 + rook_square_table[row_black][column_black]
    end
    if piece == Piece(BLACK, QUEEN)
        score += -900 + queen_square_table[row_black][column_black]
    end
    if piece == Piece(BLACK, KING)
        score += -10000000 + king_square_table[row_black][column_black]
    end
    return score

end
function evaluate_board(chessboard)
    summe = 0
    side = sidetomove(chessboard)
    for square in range(1, stop = 64, step = 1)
        summe += piece_value(pieceon(chessboard, Square(square)), square, chessboard)
        i = square
    end
    if ischeckmate(chessboard)
        summe += side == WHITE ? 10000000 : -10000000
    end
    if ischeck(chessboard)
        summe += side == WHITE ? 10 : -10
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
    all_moves_tuple = sort!(isort, lt = (x, y)->(x[1] > y[1]), rev = r)
    all_moves_sorted = last.(all_moves_tuple)
    return all_moves_sorted


end