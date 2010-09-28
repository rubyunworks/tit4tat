#!/usr/bin/ruby

require 'socket' # TCP communication
require 'tictactoe'

class TicTacToeClient

  attr_accessor :player_number
  
  private
  def decode_board(line)
    Board.new(line.gsub(/[^XO]/, '').length % 2, line.scan(/[_XO]{3}/).map{|row| row.scan(/[_XO]/).map{ |c| c == '_' ? nil : (c == 'X' ? '0' : 1) } })
  end
  
  public
  def initialize(host, port)
    @ants = {}
    @socket = TCPSocket.new(host, port)
    puts "Connected to: #{@socket.gets}"
    line = @socket.gets
    raise "Unexpected answer: #{line}" unless /([OX]+)\s+(\d+)x(\d+)/ =~ line
    @player_number = ($1 == 'X' ? 0 : 1)
    raise 'Can only play field of size 3x3' unless $2.to_i == 3 and $3.to_i == 3    
  end

  def assign_player(player)
    @player = player
    @player.new_game(@player_number)
    @socket.puts "Hello. Brian's AI is charging..."
    @board = decode_board(@socket.gets)
    puts @board
    self
  end

  def play
    while line = @socket.gets
      case line
      when /^move/
        move = @player.choose_move(@board)
        @socket.puts "#{move.x},#{move.y}"
      when /^win/
        puts "You have won"
        break
      when /^lose/
        puts "You have lost"
        break
      when /^draw/
        puts "You have drawn"
        break
      else
        @board = decode_board(line)
        puts @board
      end
    end
    @socket.close
  end
  
end


if __FILE__ == $0
  client = TicTacToeClient.new('localhost', 1276)
  require 'tictactoe-interface'
  i = Interface::NaturalIntelligence.new

  client.assign_player(i)
  client.play
end
