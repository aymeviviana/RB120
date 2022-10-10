require "yaml"
MESSAGE = YAML.load_file("rps_bonus.yml")

module Promptable
  def user_says_yes?(msg)
    answer = nil
    loop do
      puts msg
      answer = gets.chomp.downcase
      break if ["y", "yes", "n", "no"].include?(answer)
      puts "Sorry, please enter 'y' or 'n'"
    end
    ["y", "yes"].include?(answer)
  end
end

class Move
  VALUES = ["rock", "paper", "scissors", "lizard", "spock"]
  attr_reader :value

  def initialize(value)
    @value = value
  end

  def >(other_move)
    winning_scenarios = {
      "rock" => ["scissors", "lizard"],
      "paper" => ["spock", "rock"],
      "scissors" => ["lizard", "paper"],
      "lizard" => ["spock", "paper"],
      "spock" => ["rock", "scissors"]
    }
    winning_scenarios[value].include?(other_move.value)
  end

  def <(other_move)
    losing_scenarios = {
      "rock" => ["paper", "spock"],
      "paper" => ["scissors", "lizard"],
      "scissors" => ["rock", "spock"],
      "lizard" => ["scissors", "rock"],
      "spock" => ["paper", "lizard"]
    }
    losing_scenarios[value].include?(other_move.value)
  end
end

class Player
  attr_reader :move, :name

  def initialize
    set_name
  end

  private

  attr_writer :move, :name
end

class Human < Player
  def choose
    choice = nil
    loop do
      puts MESSAGE["move_options"]
      choice = gets.chomp
      break if Move::VALUES.include?(choice)
      puts "Sorry, invalid choice."
    end
    self.move = Move.new(choice)
  end

  private

  def set_name
    n = nil
    loop do
      puts "What's your name?"
      n = gets.chomp
      break unless n.empty?
      puts "Sorry, name must not be empty"
    end
    self.name = n
  end
end

class Robot < Player
  def initialize(name)
    @name = name
  end

  def choose
    mv = Move::VALUES.sample
    self.move = Move.new(mv)
  end
end

class Larry < Robot
  def choose
    self.move = Move.new("lizard")
  end
end

class Johnny < Robot
  def choose
    num = rand(1..10)
    mv = if num <= 7
           "scissors"
         else
           ["rock", "lizard", "spock"].sample
         end
    self.move = Move.new(mv)
  end
end

class Bob < Robot
end

class Score
  MAX_ROUNDS = 3
  attr_reader :tally

  def initialize
    @tally = Hash.new(0)
  end

  def display(player)
    tally[player.name]
  end

  def update(player)
    tally[player.name] += 1
  end

  def reset
    self.tally = Hash.new(0)
  end

  private

  attr_writer :tally
end

class Record
  def initialize
    @list = {}
  end

  def update(plyr)
    if list.key?(plyr.name)
      list[plyr.name] << plyr.move.value
    else
      list[plyr.name] = [plyr.move.value]
    end
  end

  def display(plyr1, plyr2)
    puts "| Move# |#{plyr1.name.center(15)}|#{plyr2.name.center(15)}|"

    plyr1_moves = list[plyr1.name]
    plyr1_moves.each_with_index do |move, idx|
      plyr2_moves = list[plyr2.name][idx]
      puts "|   #{idx + 1}   |#{move.center(15)}|#{plyr2_moves.center(15)}|"
    end
  end

  def reset
    self.list = {}
  end

  private

  attr_accessor :list
end

class RPSGame
  def initialize
    clear_screen
    display_welcome_message
    @human = Human.new
    @robot = [Larry.new("Larry"), Johnny.new("Johnny"), Bob.new("Bob")].sample
    @score = Score.new
    @list_of_moves = Record.new
    display_competitor_name
  end

  include Promptable

  def play
    loop do
      game_on
      display_game_results
      break unless user_says_yes?(MESSAGE["play_again"])
      clear_screen
    end
    display_goodbye_message
  end

  private

  attr_reader :human, :robot, :score, :list_of_moves

  def display_welcome_message
    puts MESSAGE["welcome"]
    puts MESSAGE["game_length"]
    sleep 2
    puts ""
  end

  def display_competitor_name
    puts ""
    puts "Hello #{human.name}. You'll be playing against #{robot.name} today."
    sleep 1.5
    puts ""
  end

  def game_on
    loop do
      next_round
      break if game_over?
    end
  end

  def next_round
    human.choose
    robot.choose
    list_of_moves.update(human)
    list_of_moves.update(robot)
    display_choices
    display_round_winner
    update_score
    display_score
  end

  def display_choices
    sleep 1.5
    puts ""
    puts "#{human.name} chose #{human.move.value.capitalize}"
    sleep 1.5
    puts "#{robot.name} chose #{robot.move.value.capitalize}"
    sleep 1.5
  end

  def display_round_winner
    if @human.move > @robot.move
      display_winning_move(human, robot)
      puts "#{@human.name} wins this round!"
    elsif @human.move < @robot.move
      display_winning_move(robot, human)
      puts "#{@robot.name} wins this round!"
    else
      puts "---It's a tie!---"
    end
  end

  def display_winning_move(plyr1, plyr2)
    winning_move = plyr1.move.value.capitalize
    losing_move = plyr2.move.value.capitalize
    puts "#{winning_move} beats #{losing_move}"
    sleep 1.5
  end

  def update_score
    if human.move > robot.move
      score.update(human)
    elsif human.move < robot.move
      score.update(robot)
    end
  end

  def display_score
    sleep 1.5
    puts ""
    puts "SCOREBOARD:"
    puts "#{human.name}: #{score.display(human)}"
    puts "#{robot.name}: #{score.display(robot)}"
    puts ""
    sleep 1.5
  end

  def game_over?
    score.tally.value?(Score::MAX_ROUNDS)
  end

  def display_game_results
    game_winner = score.tally.key(Score::MAX_ROUNDS)
    puts "That's #{Score::MAX_ROUNDS} wins! #{game_winner} wins the game!"
    sleep 1.5
    puts ""
    display_list_of_moves if user_says_yes?(MESSAGE["list_of_moves"])
  end

  def display_list_of_moves
    puts ""
    list_of_moves.display(human, robot)
    reset_game
    puts ""
  end

  def reset_game
    score.reset
    list_of_moves.reset
  end

  def clear_screen
    system "clear"
  end

  def display_goodbye_message
    puts MESSAGE["goodbye"]
  end
end

RPSGame.new.play
