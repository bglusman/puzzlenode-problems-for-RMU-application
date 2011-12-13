require 'forwardable'

module Chess
  BOARD_SIZE = 8
  NORTH = 1 #using to multiply side for pawn direction, good or bad clever?
  SOUTH = -1

  class Validator
    def initialize(board_file)
      @board = populate_board(board_file)
    end

    def output(outfile, move_data)
      output = ""
      move_data.split("\n").each do |line|
        origin, destination = algebra_to_pos(line.split.first), algebra_to_pos(line.split.last)
        output += @board.legal_move(origin, destination) ? "LEGAL\n" : "ILLEGAL\n"
      end
      File.open(outfile, 'w') do|f|
        f.write(output)
      end
    end

    def populate_board(board_file)
      white = Color.new(NORTH, "w") # not which side they're on, but where pawns move, advancing direction
      black = Color.new(SOUTH, "b")
      white.other_color, black.other_color = black, white

      board_file.split("\n").each_with_index do|row, row_inverse_index|
        row.split.each_with_index do|piece, col_index|
          current_color = piece[0] == (white.symbol) ? white : black
          position = Position.get(col_index+1, BOARD_SIZE - row_inverse_index)
          current_color << piece_class(piece[1]).new(current_color, position) if piece_class(piece[1])
        end
      end

      board = Game.new(white, black)
    end

    def piece_class(symbol)
      {
        "K" => King,
        "Q" => Queen,
        "B" => Bishop,
        "R" => Rook,
        "N" => Knight,
        "P" => Pawn
      }[symbol]
    end

    def algebra_to_pos(pair)
      algebra, row = pair[0], pair[1].to_i

      letter, col = 'a', 1
      letter, col = letter.succ, col.succ while letter != algebra

      Position.get(col, row)
    end
  end

  class Game
    def initialize(color1, color2)
      @color1, @color2 = color1, color2
    end

    def legal_move(origin, destination)
      return false unless origin.occupied?
      return false unless origin.occupant.valid_move(destination)
      occupant = origin.occupant
      simulate_move(origin, destination){occupant.color.king.safe?}
    end

    def simulate_move(origin, destination)
      raise "no block" unless block_given?
      captured_piece = destination.occupant #nil or piece
      origin.occupant.position = destination
      destination.occupant = origin.occupant
      origin.occupant = nil
      result = yield
      origin.occupant = destination.occupant
      destination.occupant.position = origin
      destination.occupant = captured_piece

      result
    end
  end

  class Piece
    attr_accessor :color, :position
    def initialize(color, position)
      @color, @position = color, position
      @position.occupant = self
    end

    def self.pieces
      @pieces ||= {}
    end

    def self.get(symbol)
      @init ||= subclasses.each {|subclass| Piece.pieces[subclass.symbol] = subclass}
      pieces[symbol]
    end

    def self.subclasses
      @subclasses ||= ObjectSpace.each_object(Class).select { |klass| klass < self }
    end

    def valid_move(pos)
      (!pos.occupied? || pos.occupant.color != color) && in_movement_range(pos) && unblocked_to(pos)
    end

    def in_movement_range(pos)
      movement_squares.include?(pos)
    end

    def unblocked_to(pos)
      squares_to(pos).reduce(true) {|accum, sq| accum &&  !sq.occupied?} && (!pos.occupied? || pos.occupant.color != color)
    end

    def squares_to(pos)
      col_diff = (position.col - pos.col).abs.nonzero?
      row_diff = (position.row - pos.row).abs.nonzero?
      min = [row_diff, col_diff].compact.min

      if min < 2
        [] # too close to have vector-able squares in between them
      elsif [row_diff, col_diff].include?(nil)
        orthogonal_squares_to(pos)
      else
        diagonal_squares_to(pos)
      end
    end

    def orthogonal_squares_to(pos)

      lower_col = position.col < pos.col  #self is lower than other
      lower_row = position.row < pos.row
      col_diff = (position.col - pos.col).abs.nonzero?
      row_diff = (position.row - pos.row).abs.nonzero?

      squares = []
      if row_diff && lower_row  # -1 diff to only get squares between targets, no overlap
        1.upto(row_diff - 1) {|x| squares << position.row_diff(x)}
      elsif row_diff && !lower_row
        1.upto(row_diff - 1) {|x| squares << position.row_diff(-x)}
      elsif col_diff && lower_col
        1.upto(col_diff - 1) {|x| squares << position.col_diff(x)}
      elsif col_diff && !lower_col
        1.upto(col_diff - 1) {|x| squares << position.col_diff(-x)}
      else
        squares=[]  #not orthoganal
      end

      squares.compact
    end

    def diagonal_squares_to(pos)
      lower_col_and_row = position.col < pos.col && position.row < pos.row
      higher_col_and_row = position.col > pos.col && position.row > pos.row
      lower_col_higher_row = position.col < pos.col && position.row > pos.row
      higher_col_lower_row = position.col > pos.col && position.row < pos.row
      col_diff = (position.col - pos.col).abs.nonzero?
      row_diff = (position.row - pos.row).abs.nonzero?

      squares = []
      if lower_col_and_row
        1.upto(row_diff - 1) {|x| squares << row_col_together(x)}
      elsif higher_col_and_row
        1.upto(row_diff - 1) {|x| squares << row_col_together(-x)}
      elsif lower_col_higher_row
        1.upto(col_diff - 1) {|x| squares << row_col_opposite(x)}
      elsif higher_col_lower_row
        1.upto(col_diff - 1) {|x| squares << row_col_opposite(-x)}
      else
        squares=[]  #not diagonal
      end

      squares.compact
    end

    def row_plus(offset)
      Position.get(position.col, position.row + offset)
    end

    def col_plus(offset)
      Position.get(position.col + offset, position.row)
    end

    def row_col_together(offset)
      Position.get(position.col+offset, position.row+offset)
    end

    def row_col_opposite(offset)
      Position.get(position.col+offset, position.row-offset)
    end

    def row_by_col_variants
      variants_helper(:row_col_together, :row_col_opposite)
    end

    def row_and_col_variants
      variants_helper(:row_plus, :col_plus)
    end

    def variants_helper(function1, function2, low=1, high=BOARD_SIZE)
      moves = low.upto(high).reduce([]) do |accum, x|
        accum << self.send(function1, x)
        accum << self.send(function2, x)
        accum << self.send(function1, -x)
        accum << self.send(function2, -x)
      end

      moves.compact.uniq
    end

    def movement_squares
      raise "Override movement_squares in subclass"
    end
  end

  class Color
    extend Forwardable
    attr_accessor :king, :other_color, :pieces, :advancing_direction, :symbol
    def_delegators :@pieces, :<<
    def initialize(advancing_direction, symbol)
      @advancing_direction, @symbol, @pieces = advancing_direction, symbol, []
    end

    def north?
      advancing_direction == SOUTH
    end

    def south?
      advancing_direction == NORTH
    end

  end

  class Position  #TODO - refactor Position.get to be Game#get, and make all positions or pieces know their board to encapuslate game better
    attr_reader :col, :row, :occupant
    def self.get(col, row)
      # debugger
      return nil if row < 1 || col < 1 || row > BOARD_SIZE || col > BOARD_SIZE
      existing = defined.select {|pos| pos.col == col && pos.row == row}
      existing == [] ? new(col, row) : existing.first
    end

    def occupant=(piece)
      @occupant=piece
    end

    def occupied?
      occupant.is_a?(Piece)
    end

    def self.defined
      @defined ||= []
    end

    def row_diff(x)
      self.class.get(col, row+x)
    end

    def col_diff(x)
      self.class.get(col+x, row)
    end

    private
    def initialize(col, row)
      @col, @row = col, row
      self.class.defined << self
    end
  end
end