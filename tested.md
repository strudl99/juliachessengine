# Tested times 
## FEN: rnbqk1nr/p4p2/8/1pppp1pp/2P1Pb2/2BP1N2/PP3PPP/RN1QKB1R w KQkq - 0 1

### Not Multithreading pickNextMoveFast
```bash
info score cp 185 currmove c4d5 depth 1 nodes 92 time 14 pv c4d5 
info score cp 165 currmove c4d5 depth 2 nodes 973 time 1 pv c4d5 c8g4 
info score cp 187 currmove c4d5 depth 3 nodes 3127 time 2 pv c4d5 c8g4 f1e2 
info score cp 200 currmove c4d5 depth 4 nodes 14316 time 13 pv c4d5 c8g4 h2h3 g4f3 
info score cp 208 currmove c4d5 depth 5 nodes 41094 time 36 pv c4d5 b8d7 g2g3 b5b4 g3f4 
info score cp 208 currmove c4d5 depth 6 nodes 185041 time 276 pv c4d5 b8d7 g2g3 b5b4 g3f4 b4c3 
info score cp 208 currmove c4d5 depth 7 nodes 606236 time 423 pv c4d5 b8d7 g2g3 b5b4 g3f4 b4c3 
info score cp 208 currmove c4d5 depth 8 nodes 2430287 time 1838 pv c4d5 b8d7 g2g3 b5b4 g3f4 b4c3
```
### Multithreading pickNextMoveFast
Without any form of sync
```bash
info score cp 185 currmove c4d5 depth 1 nodes 99 time 69 pv c4d5 
info score cp 165 currmove c4d5 depth 2 nodes 1059 time 7 pv c4d5 c8g4 
info score cp 187 currmove c4d5 depth 3 nodes 3298 time 17 pv c4d5 c8g4 f1e2 
info score cp 200 currmove c4d5 depth 4 nodes 18044 time 159 pv c4d5 c8g4 h2h3 g4f3 
info score cp 208 currmove c4d5 depth 5 nodes 49504 time 255 pv c4d5 b8d7 g2g3 b5b4 g3f4 
info score cp 208 currmove c4d5 depth 6 nodes 238642 time 1325 pv c4d5 b8d7 g2g3 b5b4 g3f4 b4c3 
info score cp 208 currmove c4d5 depth 7 nodes 1145676 time 6741 pv c4d5 b8d7 g2g3 b5b4 g3f4 b4c3 
info score cp 208 currmove c4d5 depth 8 nodes 3164526 time 17797 pv c4d5 b8d7 g2g3 b5b4 g3f4 b4c3
```