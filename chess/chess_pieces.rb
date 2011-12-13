require_relative 'chess_classes'

module Chess
  class Pawn < Piece

    def movement_squares
      squares = [] << row_plus(color.advancing_direction)
      squares << row_plus(2 * color.advancing_direction) if home_row?
      diag1=position.row_diff(color.advancing_direction).col_diff(1)
      diag2=position.row_diff(color.advancing_direction).col_diff(-1)
      squares << diag1 if diag1 && diag1.occupied? && diag1.occupant.color == color.other_color
      squares << diag2 if diag2 && diag2.occupied? && diag2.occupant.color == color.other_color

      squares
    end

    def home_row? #south is advancing north, and vice versa
      color.south? && position.row==2 || (color.north? && position.row == (BOARD_SIZE-1))
    end
  end

  class King < Piece
    def initialize(color, position)
      color.king = self unless color.nil?
      super
    end

    def safe?
      actual_attackers.empty?
    end

    def potential_attackers
      color.other_color.pieces.compact.select do |piece|
        piece.in_movement_range(position)
      end
    end

    def actual_attackers
      potential_attackers.select do |attacker|
        attacker.valid_move(position)
      end
    end

    def movement_squares

      moves = []
      -1.upto(1) do |posneg|
        next if posneg == 0
        moves << row_plus(posneg)
        moves << col_plus(posneg)
        moves << row_col_together(posneg)
        moves << row_col_opposite(posneg)
      end

      moves.compact
    end
  end

  class Queen < Piece
    def movement_squares
      row_and_col_variants + row_by_col_variants
    end
  end

  class Rook < Piece
    def movement_squares
      row_and_col_variants
    end
  end

  class Bishop < Piece
    def movement_squares
      row_by_col_variants
    end
  end

  class Knight < Piece
    def movement_squares
      moves = []
      1.upto(2) do |column|
        1.upto(2) do |row|
          -1.upto(1) do |posneg|
            moves << Position.get(position.col + column*posneg,
              position.row + row*posneg) unless column == row || posneg == 0
            moves << Position.get(position.col + column*posneg,
              position.row - row*posneg) unless column == row || posneg == 0
          end
        end
      end

      moves.compact
    end
  end
end