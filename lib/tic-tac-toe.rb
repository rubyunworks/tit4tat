
AI_DEFAULT_FITNESS = 25
AI_FITNESS_WIN = 5
AI_FITNESS_LOSS = -10
AI_FITNESS_DRAW = 0

MOVE_DELAY = 0.0
GAME_DELAY = 0.0
GEN_DELAY = 0.0


class Population
  attr_reader :max
  def initialize( max )
    @max = max
    @pop = []
    @births = 0
    @genbirths = 0
    @max.times{ |i| @pop[i] = AIPlayer.new }
  end

  def max_population
    @max
  end

  def breed( player1, player2 )
    #if compatible( player1, player2 )
      @births += 1
      @genbirths += 1
      new_genetics = []
      player1.genetics.each { |g| new_genetics << g.dup }
      #player1.genetics.each{ |g| new_genetics << g if [(rand*2).to_i] == 0 }
      player2.genetics.each{ |g| new_genetics << g.dup if [(rand*2).to_i] == 0 }
      return AIPlayer.new(new_genetics).mutate
    #end
  end

  #def compatible( p1, p2 )
  #  true
  #end

  def evolve( generations, game_cycles )
    @genbirths = 0
    cycles = game_cycles * max_population
    generations.times { |gencnt|
      if $VERBOSE
        puts "\e[2J\e[0;0H"
        puts "\e[0;0HGeneration: #{gencnt} "
        puts "\e[0;20HBirths: #{@genbirths} "
      end
      @genbirths = 0
      cycles.times { |i|
        puts "\e[2;0HGame: #{i} "
        pX = @pop[(rand*@pop.length).to_i]
        pO = @pop[(rand*@pop.length).to_i]
        game = Game.new(pX, pO)
        game.play
      }
      # The weak parish
      @pop.reject!{ |s| s.fitness <= 0 }
      # The strong breed
      last = 0
      breeding_rates = []
      @pop.each{ |player|
        breeding_rates << (last..(last + player.fitness))
        last += player.fitness + 1
      }
      m1 = (rand*last).to_i
      m2 = (rand*last).to_i
      (@max - @pop.length).times {
        p1r = breeding_rates.find{ |br| br.include?(m1) }
        p2r = breeding_rates.find{ |br| br.include?(m2) }
        p1 = @pop[breeding_rates.index(p1r)]
        p2 = @pop[breeding_rates.index(p2r)]
        @pop << breed( p1, p2 )
      }
    }
    @genbirths = 0
  end

  def best_of_breed
    return @pop.max
  end

  def show
    puts
    @pop.each_with_index { |player, i|
      print "%3s)" % ["#{i+1}"]
      puts " #{player}\n"
    }
    puts
  end
end


class BasePlayer
  X = 'X' ; O = 'O'
  RC  = { 256=>[0,0], 128=>[1,0], 64=>[2,0],   [0,0]=>256, [1,0]=>128, [2,0]=>64,
           32=>[0,1],  16=>[1,1],  8=>[2,1],   [0,1]=>32,  [1,1]=>16,  [2,1]=>8,
            4=>[0,2],   2=>[1,2],  1=>[2,2],   [0,2]=>4,   [1,2]=>2,   [2,2]=>1   }

  # Ready for a new game, need a new board.
  def newgame( dim_y=3, dim_x=3 )
    return nil if dim_y != 3 or dim_x != 3
    @board = Board.new
    return true
  end
  # Takes a liner board string and has the board parse it.
  def board=( sboard )
    if Board === sboard
      @board = sboard.dup
    else
      @board.parse( sboard )
    end
  end
  # Takes a turn as 'X' or 'O' and returns the [row,col] move.
  def move( turn )
    RC[pot[(rand*pot.length).to_i]]  # random for basic player
  end
  # effects of a win, loose, draw or cheat
  def win; end
  def loose; end
  def draw; end
  def cheat; end
  # --------------
  private
    def pot ; @board.pot ; end
    def enemy(turn) ; @board.state[switch(turn)] ; end
    def mine(turn) ; @board.state[turn] ; end
    def switch( turn )
      turn == O ? X : O 
    end
  #end private
end

# Artifically Integlligent Evolving Player
class AIPlayer < BasePlayer
  AST = [ "|m", "&m", "^m",
          "|e", "&e", "^e",
          "|s", "&s", "^s",
          "|t", "&t", "^t"  ]

  DEFUALT_FITNESS = AI_DEFAULT_FITNESS 

  def initialize( genetics=nil )
    @fitness = DEFUALT_FITNESS 
    if genetics
      @genetics = genetics
    else
      @genetics = random_genetics
    end
  end

  def to_yaml_properties
    [ '@fitness', '@genetics' ]
  end

  attr_accessor :fitness, :genetics

  def random_genetics
    g = []
    c = (rand*6).to_i + 1
    n = (rand*6).to_i + 1
    c.times{
      s = (0..n).collect{ |n| a=(rand*AST.length).to_i; AST[a] }
      g << s
    }
    g
  end

  def mutate
    geneid = (rand*genetics.length).to_i
    gene = genetics[geneid]
    case (rand*4).to_i
    when 0 # drop
      gene.delete_at((rand*gene.length).to_i)
      genetics.delete_at(geneid) if gene.empty?
    when 1 # add ast
      gene.insert((rand*gene.length).to_i, AST[(rand*AST.length).to_i])
    when 2 # add random
      i = (rand*511).to_i
      case (rand*3).to_i
      when 0 then gene.insert((rand*gene.length).to_i, "|#{i}")
      when 1 then gene.insert((rand*gene.length).to_i, "&#{i}")
      when 2 then gene.insert((rand*gene.length).to_i, "^#{i}")
      end
    else
      # got off this time!
    end
    self
  end

  def win ; @fitness += AI_FITNESS_WIN ; end
  def loose ; @fitness += AI_FITNESS_LOSS ; end
  def draw ; @fitness += AI_FITNESS_DRAW ; end
  #def cheat ; @fitness -= 15 ; end

  # Takes a turn as 'X' or 'O' and returns the [row,col] move.
  def move( turn )
    @turn = turn
    best = nil; max = -1
    pot.each{ |slot|
      w = weigh(slot, turn)
      if w > max
        max = w
        best = slot
      end
    }
    return RC[best]
  end
  
  def weigh(slot, turn)
    s = slot
    t = ( turn == X ? 0b111111111 : 0b000000000 )
    e, m = enemy(turn), mine(turn)
    g = nil
    begin
      sum = 0
      @genetics.each { |g|
        gc = "#{g}"[1..-1]
        sum += eval(gc) 
      }
      return (sum / @genetics.length)
    rescue
      puts "ERROR"
      p "gene: #{g.inspect}"
      exit 0
    end
  end

  def <=>( other )
    self.fitness <=> other.fitness  
  end

  def to_s
    g = @genetics.collect{ |strand| strand.join('')[1..-1] }
    s = ''
    s << "[" << g.join(', ') << "]"
    s << ":#{fitness}"
    s
  end
end


class HumanPlayer < BasePlayer

  INPUTMAP = { 7=>8, 8=>7, 9=>6, 4=>5, 5=>4, 6=>3, 1=>2 , 2=>1, 3=>0 }

  def move( turn )
    loop do
      puts "\e[2J\e[0;0H"
      puts "Selection Map"
      puts " 7 8 9 "
      puts " 4 5 6 "
      puts " 1 2 3 "
      puts
      puts "Current Board"
      puts @board.grid_image
      print "\nYou are #{turn}. Your move [0-8|x]? "
      inp = gets.strip
      inp.downcase!
      case inp
      when 'x'
        exit 0 
      else
        if inp =~ /[123456789]/
          i = 2**(INPUTMAP[inp.to_i])
          if pot.include?( i )
            return RC[i]
          else
            puts "Invalid move. Try again."; sleep 0.25
          end
        else
          puts "Invalid move. Try again."; sleep 0.25
        end
      end
    end
  end

  def win ; puts "You Win! :)" ; sleep 3 ; end
  def loose ; puts "You Loose! :(" ; sleep 3 ; end
  def draw ; puts "Cats, You tied. :|" ; sleep 3 ; end
  #def cheat ; puts "You cheat! :[" ; end
end


# The board is represented in a non-traditional
# manner to make it more useful for transformitive logic.
# It is broken down into three parts: the state of X,
# the state of O, and the pot. States are simply binary
# representations of the slots in which the player has 
# placed their mark. The pot is an array of the remaining
# slots. Those slots are number as follows:
#
#  256 | 128 |  64
# -----+-----+-----
#   32 | 16  |  8
# -----+-----+-----
#   4  |  2  |  1  
#
class Board
  X = 'X' ; O = 'O'
  RC  = { 256=>[0,0], 128=>[1,0], 64=>[2,0],   [0,0]=>256, [1,0]=>128, [2,0]=>64,
           32=>[0,1],  16=>[1,1],  8=>[2,1],   [0,1]=>32,  [1,1]=>16,  [2,1]=>8,
            4=>[0,2],   2=>[1,2],  1=>[2,2],   [0,2]=>4,   [1,2]=>2,   [2,2]=>1   }
  POT = [256,128,64,32,16,8,4,2,1]
  attr_reader :state, :pot
  def initialize
    @state = {}
    @state[X] = 0b000000000
    @state[O] = 0b000000000
    @pot = POT.dup
  end
  # parses a linear representation of the board
  def parse( board )
    @state[X] = 0b000000000
    @state[O] = 0b000000000
    @pot = POT.dup
    b = board.gsub(' ','')
    b.length.times{ |i|
      case b[-i] 
      when 'X'
        @state[X] = @state[X] & 2**i 
        @pot.delete(2**i)
      when 'O'
        @state[O] = @state[O] & 2**i
        @pot.delete(2**i)
      end
    }
  end
  def move( turn, y, x )
    @state[turn] = @state[turn] | RC[[y,x]]
    @pot.delete( RC[[y,x]] )
  end
  def display( turn=nil ) ; puts to_s ; end
  # Builds a grid representation of the board
  def grid_image
    s = ''
    s << " %s %s %s \n" % [own(256), own(128), own(64)]
    s << " %s %s %s \n" % [own(32),  own(16),  own(8)]
    s << " %s %s %s \n" % [own(4),   own(2),   own(1)]
    s
  end
    # builds a linear representation of the board
  def line_image
    "%s%s%s %s%s%s %s%s%s" % POT.collect{ |i| own(i) }
  end
  def own(n)
    return 'X' if @state[X] & n == n
    return 'O' if @state[O] & n == n
    return '_'
  end
  alias to_s line_image
end


class Game
  X = 'X' ; O = 'O'; C = 'C'

  WINNING_COMBOS = [
    0b111000000,
    0b000111000,
    0b000000111,
    0b100100100,
    0b010010010,
    0b001001001,
    0b100010001,
    0b001010100
  ]

  attr_reader :board

  def initialize( x_player, o_player )
    # board
    @board = Board.new
    # players
    @player = {}
    @player[X] = x_player
    @player[O] = o_player
  end

  def play
    # get them ready to play
    @player[X].newgame
    @player[O].newgame
    #
    puts "\e[3;0H"
    #
    @move_cnt = 0
    turn = O
    until w = winner?
      turn = switch( turn )
      #display( turn ) if $VERBOSE
      # player make move
      @player[turn].board = @board    # tell the player what the board looks like
      m = @player[turn].move( turn )  # ask for move
      @board.move( turn, *m )         # update the game board
      # show results
      display( turn ) if $VERBOSE
      sleep MOVE_DELAY
    end
    case w
     when C
      puts "\e[3;0HCats       " if $VERBOSE
      @player[X].draw
      @player[O].draw
     else
      puts "\e[3;0HWinner #{w}" if $VERBOSE
      @player[w].win
      @player[switch(w)].loose
    end
    sleep GAME_DELAY
  end

  def switch( turn ) ; turn == O ? X : O ; end

  def winner?
    WINNING_COMBOS.each do |wc|
      return X if @board.state[X] & wc == wc
      return O if @board.state[O] & wc == wc
    end
    return C if @board.pot.empty?
    nil
  end

  def display( turn )
    puts @board.grid_image
  end

  def sym(n)
    return "X" if @board[X] & n == n
    return "O" if @board[O] & n == n
    "_"
  end

end
