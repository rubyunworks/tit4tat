class Move
  attr_accessor :x, :y, :player
  
  def initialize(x, y, player)
    @x, @y, @player = x, y, player
  end
  
  def to_s
    "Player #{player} set to (#{x},#{y})"
  end
  
  def inspect
    super()[0..-2] + " ID: #{move_id}>"
  end
  
  def move_id
    (self.x) + (self.y << 4) + (self.player << 4)
  end
end

class Board
  attr_reader :player

  def cells
    @field
  end
      
  def initialize(player = 0, field = Array.new(3) { Array.new(3) { nil } })
    @player = player
    @field = field
  end
  
  # Return allowed moves
  def moves
    moves = []
    @field.each_with_index do | row, y |
      row.each_with_index do | field, x |
        moves << Move.new(x, y, self.player) unless field
      end
    end
    moves
  end
  
  # Make move
  def make(move)
    self.dup.make!(move)
  end

  # Make move
  def make!(move)
    raise 'Illegal move' if @field[move.y][move.x] or move.player != self.player or move.x < 0 or 3 <= move.x or move.y < 0 or 3 <= move.y
    @field[move.y][move.x] = move.player
    @player = 1 - @player
    self
  end

  def dup
    self.class.new(player, @field.map{|row| row.dup})
  end
  
  # Is the game finished and who has won
  private
  def winner_test(cells)
    cells.inject(cells[0]) { | player, cell | cell == player ? player : false }
  end
  
  public
  def winner
    result = nil
    @field.each           do | row | result ||= winner_test(row) end # Horizontal
    @field.transpose.each do | row | result ||= winner_test(row) end # Vertical
    result || winner_test((0..2).map{|i| @field[i][i]}) || winner_test((0..2).map{|i| @field[2-i][i]}) # Diagonal
  end
  
  def to_s
    ('+--' * 3) + "+\n" + 
      @field.map{|row| '|' + row.map{|cell| cell ? "%2d" % cell : '  ' }.join('|') + "|\n" }.join('+--' * 3 + "+\n") + 
      ('+--' * 3) + "+\n"
  end
  
  def state_id
    result = @player
    @field.each do | row | row.each do | cell | result = (result << 2) + (cell ? cell : 2) end end
    result
  end

  def final?
    self.winner || self.moves.empty?
  end
end
