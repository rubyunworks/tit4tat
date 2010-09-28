#!/usr/bin/env ruby

module Interface
  class BasicInterface
    attr_accessor :player
    
    def initialize()
    end

    def new_game(player)
      @player = player
    end

    def inform_of_move(before, after, move)
    end
  end

  # Natural Intelligence.
  #
  # The interface for the human player
  class NaturalIntelligence < BasicInterface
    def choose_move(game)
      puts "Allowed moves:"
      moves = game.moves
      moves.each_with_index do | move, i | puts "%2d) %s" % [i+1, move] end      
      begin
        print 'Choose move: '
        i = gets.to_i - 1
      end until 0 <= i and i < moves.length
      move = moves[i]
      move
    end
  end
end

$stdout.sync = true

# Take the time it took to execute the block
#
# Returns the time and the rest of the result
def time
  start_time = Time.new.to_f
  result = yield
  time = Time.new.to_f - start_time
  return time, result
end

# Let two players play against each other. Outputs state to stdout. See also #play_game_silent.
def play_game(player0, player1)
  players = [player0, player1]

  # Inform player of their color
  players.each_with_index do | interface, player | interface.new_game(player) end

  # Create a new game
  game = Board.new

  turn = 0
  until game.final?
    player = players[game.player] # Player who takes the turn

    puts "Turn: #{turn+=1}"
    puts game

    puts "Player #{game.player} is thinking..."
    time, move = time { player.choose_move(game) }
    puts "Thinking took %6.2fs" % time
    
    puts "Player #{game.player} acts: #{move}\n\n"
      
    game, old_game = game.make(move), game
    players.each do | p| p.inform_of_move(old_game, game, move) end
  end

  puts "Result:"
  puts game
  puts "Winner: #{game.winner ? "Player #{game.winner}" : 'None'}"
end

# Let two players play against each other. Produces no output. See also #play_game
def play_game_silent(player0, player1)
  players = [player0, player1]

  # Inform player of their color
  players.each_with_index do | interface, player | interface.new_game(player) end

  # Create a new game
  game = Board.new

  turn = 0
  until game.final?
    player = players[game.player]
    time, move = time { player.choose_move(game) }
    game, old_game = game.make(move), game
    players.each do | p| p.inform_of_move(old_game, game, move) end
  end  

  game.winner
end

# If this file is executed, starts a Human vs. Human game
if __FILE__ == $0 
  player0 = AI::NaturalIntelligence.new
  player1 = AI::NaturalIntelligence.new
  play_game(player0, player1)
end
