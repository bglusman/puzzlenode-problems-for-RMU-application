Chess Validator (Puzzle node problem #13)


The following snippet in an .rb file should exercise the code as I did in my tests

require_relative 'chess.rb'

board_file, moves_file = File.read('complex_board.txt'), File.read('complex_moves.txt')
@validator = Chess::Validator.new(board_file)
@validator.output("output.txt", moves_file)



Initially I tried to solve this statelessly, only calculating validity and never actually moving the pieces in my code, but I found this difficult to deal with both the kings moves that might bring him into check (a pawn cannot move to his new square unless he is in it, so it's not "under attack" until he (or someone) is there), and to deal with complexities of one of the kings pieces moving in such a way that MIGHT bring him into check, IF the piece's new position doesn't resolve the check...  in the end I wound up simulating new moves, so I think it's about 95% of an entire working chess game as a result.  On the forum it looks like Jacob may have found a different approach more in keeping with the stateless nature of the assignment, so I look forward to seeing his code.

I did want to do one further refactoring to the position class, as storing all positions in the class object is poorly encapsulated and should be on the board object instead, but I prioritized other refactorings ahead of that, and in addition there's some rigitdity in the relationship between color, board and position that reflect further deficiencies that I'd like to refactor better, but I have less clear of an idea how in the current overall design.