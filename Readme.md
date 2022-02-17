# Julia Chess Engine

This is a simple chess engine in julia using [Chess.jl](https://github.com/romstad/Chess.jl)

## Simple julia chess engine

- This engines evaluation function uses PST, isolated and passed pawn and rook open file evaluation. Also knights and bishops are getting a movability bonus.
- negamax with alphabeta pruning, MVV-LVA, killer-heuristic move ordering. Also it uses nullmove and LMR pruning. It also uses TT-tables.
- It uses a very simple time management functionality.
- Engines uses uci protocol.
