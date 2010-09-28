#!/usr/bin/ruby
#
# By: Brian Schröder
# Base on the server by Hans Fugal

Thread.abort_on_exception = true

require 'socket'
require 'tictactoe'

class TicTacToeGame
  attr_accessor :active
  
  def initialize(player1, player2)
    super()
    @active = true
    @player = [player1, player2]
    @board = Board.new
    @thread = Thread.new &method(:play_game)
  end

  def join
    @player.map! {|p| p.close if p; nil}
    @thread.join
  end
  
  protected
  def state
    @board.cells.map{|row| row.map{|cell| cell ? ['X', 'O'][cell] : '_'}.join('')}.join(' ')
  end
    
  def play_game
    until @board.final?
      $stdout.puts "Player #{@board.player}", @board, ''
      @player.each {|p| p.puts(state) }
      begin        
        @player[@board.player].puts('move')
        x, y = *@player[@board.player].gets.split(',').map{|i|Integer(i)}
        @board.make!(Move.new(x, y, @board.player))
      rescue # TODO: Catch a specific exception, otherwise here's a potentially infinite loop
        @player[@board.player].puts('move')
        retry
      end
    end
    $stdout.puts "Result:", @board, ''
    
    @player.each {|p| p.puts(state)}
    winner = @board.winner
    if winner
      @player[winner].puts('win')
      @player[1-winner].puts('lose')
    else
      @player.each { |p| p.puts('draw') }
    end
  rescue => e
    $stdout.puts 'Exception occured in active game', e
  ensure
    @player.each {|p| p.close if p}
    @active = false
  end
  
end

class TicTacToeServer < TCPServer
  attr_accessor :hello
  
  def initialize(port)
    super(port)
  end
  
  def serve_games
    @hello = "Brian's Tic-Tac-Toe server"

    @threads = []
    $stdout.sync = true
    loop do
      player0 = self.accept
      player0.puts hello
      player0.puts "X 3x3"
      $stdout.puts "First player connected: #{player0.gets}"

      player1 = self.accept
      player1.puts hello
      player1.puts "O 3x3"
      $stdout.puts "Second player connected: #{player1.gets}"

      @threads << TicTacToeGame.new(player0, player1)
    end

  ensure
    @threads.each do | thread | thread.join end
  end
end

if $0 == __FILE__
  port = (ARGV[0] || 1276).to_i
  puts "Listening on port #{port}"
  server = TicTacToeServer.new(port)
  server.serve_games
end

