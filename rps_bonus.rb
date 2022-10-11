require "yaml"
MESSAGE = YAML.load_file("rps_bonus.yml")

module Promptable
  def prompt(msg)
    puts(msg)
  end

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

  WINS = {
    "rock" => ["scissors", "lizard"],
    "paper" => ["spock", "rock"],
    "scissors" => ["lizard", "paper"],
    "lizard" => ["spock", "paper"],
    "spock" => ["rock", "scissors"]
  }

  attr_reader :value

  def initialize(value)
    @value = value
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
  include Promptable

  def choose
    choice = nil
    loop do
      prompt(MESSAGE["move_options"])
      choice = gets.chomp.downcase
      choice = translate(choice) if choice.length == 1
      break if Move::VALUES.include?(choice)
      prompt("Sorry, invalid choice.")
    end
    self.move = Move.new(choice)
  end

  private

  def translate(choice)
    case choice
    when "r" then "rock"
    when "p" then "paper"
    when "s" then "scissors"
    when "l" then "lizard"
    when "k" then "spock"
    end
  end

  def set_name
    n = nil
    loop do
      prompt("What's your name?")
      n = gets.chomp.strip
      break unless n.empty?
      prompt("Sorry, name must not be empty")
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
  include Promptable

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
    prompt("| Move# |#{plyr1.name.center(15)}|#{plyr2.name.center(15)}|")

    plyr1_moves = list[plyr1.name]
    plyr1_moves.each_with_index do |move, idx|
      plyr2_moves = list[plyr2.name][idx]
      prompt("|   #{idx + 1}   |#{move.center(15)}|#{plyr2_moves.center(15)}|")
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

  def delay(duration)
    sleep(duration)
  end

  def display_welcome_message
    prompt(MESSAGE["welcome"])
    prompt(MESSAGE["game_length"])
    delay(2)
    prompt("")
  end

  def display_competitor_name
    prompt("")
    prompt("Hi #{human.name}. You'll be playing against #{robot.name} today.")
    delay(1.5)
    prompt("")
  end

  def game_on
    loop do
      next_round
      break if game_over?
      clear_screen
    end
  end

  def next_round
    human.choose
    robot.choose
    list_of_moves.update(human)
    list_of_moves.update(robot)
    display_choices
    determine_round_winner
    update_score
    display_score
  end

  def display_choices
    delay(1.5)
    prompt("")
    prompt("#{human.name} chose #{human.move.value.capitalize}")
    delay(1.5)
    prompt("#{robot.name} chose #{robot.move.value.capitalize}")
    delay(1.5)
  end

  def determine_round_winner
    human_move = @human.move.value
    robot_move = @robot.move.value

    result = if human_move == robot_move
               "It's a tie!"
             elsif Move::WINS[human_move].include?(robot_move)
               [human, robot]
             else
               [robot, human]
             end

    display_winning_move(result)
  end

  def display_winning_move(result)
    if result.class == String
      prompt(result)
    else
      winning_move = result.first.move.value.capitalize
      losing_move = result.last.move.value.capitalize
      prompt("#{winning_move} beats #{losing_move}")
      delay(1.5)
      display_round_winner(result.first)
    end
  end

  def display_round_winner(winner)
    prompt("#{winner.name} wins this round!")
  end

  def update_score
    human_move = @human.move.value
    robot_move = @robot.move.value

    if Move::WINS[human_move].include?(robot_move)
      score.update(human)
    elsif Move::WINS[robot_move].include?(human_move)
      score.update(robot)
    end
  end

  def display_score
    delay(1.5)
    prompt("")
    prompt("SCOREBOARD:")
    prompt("#{human.name}: #{score.display(human)}")
    prompt("#{robot.name}: #{score.display(robot)}")
    prompt("")
    delay(2)
  end

  def game_over?
    score.tally.value?(Score::MAX_ROUNDS)
  end

  def display_game_results
    game_winner = score.tally.key(Score::MAX_ROUNDS)
    prompt("That's #{Score::MAX_ROUNDS} wins! #{game_winner} wins the game!")
    delay(1.5)
    prompt("")
    display_list_of_moves if user_says_yes?(MESSAGE["list_of_moves"])
  end

  def display_list_of_moves
    prompt("")
    list_of_moves.display(human, robot)
    reset_game
    prompt("")
  end

  def reset_game
    score.reset
    list_of_moves.reset
  end

  def clear_screen
    system "clear"
  end

  def display_goodbye_message
    prompt(MESSAGE["goodbye"])
  end
end

RPSGame.new.play
