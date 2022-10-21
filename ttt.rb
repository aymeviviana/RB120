require "yaml"
MESSAGE = YAML.load_file("ttt.yml")

module Displayable
  def prompt(msg)
    puts msg
  end

  def display_welcome_message
    prompt(MESSAGE["welcome"])
    prompt("First player to win #{Score::MAX_ROUNDS} rounds wins the game!")
    prompt("")
  end

  def display_player_names(player1, player2)
    prompt("")
    prompt("Hi #{player1.name}! You'll be playing against #{player2.name}.")
  end

  def display_goodbye_message
    prompt(MESSAGE["goodbye"])
  end

  def display_continue_message
    prompt(MESSAGE["continue"])
    gets.chomp
  end

  def play_again?
    answer = nil
    prompt(MESSAGE["play_again"])
    loop do
      answer = gets.chomp.downcase
      break if ["y", "yes", "n", "no"].include?(answer)
      prompt(MESSAGE["yes_or_no"])
    end

    answer.start_with?("y")
  end

  def display_play_again_message
    prompt(MESSAGE["start_new_game"])
    prompt("")
  end
end

module Formattable
  def clear
    system "clear"
  end

  def joinor(array, delimiter=",", word="or")
    last_value = array.pop
    case array.length
    when 0 then last_value
    else "#{array.join(delimiter)} #{word} #{last_value}"
    end
  end
end

class Score
  include Displayable

  MAX_ROUNDS = 3

  attr_reader :tally

  def initialize
    @tally = Hash.new(0)
  end

  def display(player)
    tally[player]
  end

  def detect_game_winner
    tally.key(MAX_ROUNDS)
  end

  def reset
    self.tally = Hash.new(0)
  end

  private

  attr_writer :tally
end

class Board
  THREE_IN_A_ROW = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] +
                   [[1, 4, 7], [2, 5, 8], [3, 6, 9]] +
                   [[1, 5, 9], [3, 5, 7]]

  attr_reader :squares

  def initialize
    @squares = {}
    reset
  end

  def []=(key, marker)
    squares[key].marker = marker
  end

  def unmarked_keys
    squares.keys.select { |key| squares[key].unmarked? }
  end

  def markers_at(row)
    squares.values_at(*row).map(&:marker)
  end

  def full?
    unmarked_keys.empty?
  end

  def someone_won_round?
    !!winning_marker
  end

  def winning_marker
    THREE_IN_A_ROW.each do |row|
      markers_array = markers_at(row)
      return markers_array.first if three_identical_markers?(markers_array)
    end
    nil
  end

  def reset
    1.upto(9) { |num| squares[num] = Square.new }
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def draw
    puts "     |     |     "
    puts "  #{squares[1]}  |  #{squares[2]}  |  #{squares[3]}  "
    puts "     |     |     "
    puts "-----+-----+-----"
    puts "     |     |     "
    puts "  #{squares[4]}  |  #{squares[5]}  |  #{squares[6]}  "
    puts "     |     |     "
    puts "-----+-----+-----"
    puts "     |     |     "
    puts "  #{squares[7]}  |  #{squares[8]}  |  #{squares[9]}  "
    puts "     |     |     "
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  private

  def three_identical_markers?(markers_array)
    markers_array.delete(Square::EMPTY_MARKER)
    return false if markers_array.length < 3
    markers_array.uniq.length == 1
  end
end

class Square
  EMPTY_MARKER = " "

  attr_accessor :marker

  def initialize(marker=EMPTY_MARKER)
    @marker = marker
  end

  def unmarked?
    marker == EMPTY_MARKER
  end

  private

  def to_s
    marker
  end
end

class Player
  attr_accessor :marker, :name
end

class Human < Player
  include Displayable
  def select_name
    name = nil
    prompt(MESSAGE["player_name"])

    loop do
      name = gets.chomp.strip
      break unless name.empty?
      prompt(MESSAGE["try_name_again"])
    end
    self.name = name
  end
end

class Computer < Player
  def initialize
    @name = ["BB8", "R2D2", "C3PO"].sample
  end

  def detect_winning_square(board, player)
    !!detect_square(board, player)
  end

  def detect_blocking_square(board, player)
    !!detect_square(board, player)
  end

  def detect_square(board, player)
    Board::THREE_IN_A_ROW.each do |row|
      markers_arr = board.markers_at(row)
      marked_square_count = markers_arr.count(player.marker)
      empty_square_count = markers_arr.count(Square::EMPTY_MARKER)

      if marked_square_count == 2 && empty_square_count == 1
        empty_square_idx = markers_arr.index(Square::EMPTY_MARKER)
        return row[empty_square_idx]
      end
    end
    nil
  end

  def middle_square_available?(board, middle)
    board.squares[middle].unmarked?
  end

  def select_square(number, board)
    board[number] = marker
  end
end

class TTTGame
  include Displayable
  include Formattable

  MARKER_1 = "X"
  MARKER_2 = "O"
  @@first_to_move = :human_player

  def initialize
    @board = Board.new
    @human = Human.new
    @computer = Computer.new
    @score = Score.new
    @current_player = @@first_to_move
  end

  def play
    clear
    display_welcome_message
    select_player_name
    display_player_names(human, computer)
    display_marker_message
    display_first_player_message
    main_game
    display_goodbye_message
  end

  private

  attr_reader :human, :computer, :board, :score

  def display_marker_message
    prompt("")
    prompt("Do you prefer #{TTTGame::MARKER_1}'s or #{TTTGame::MARKER_2}'s?")
    prompt("Enter '#{TTTGame::MARKER_1}' or '#{TTTGame::MARKER_2}'.")
    select_marker
  end

  def select_marker
    choice = nil
    loop do
      choice = gets.chomp.upcase
      break if [MARKER_1, MARKER_2].include?(choice)
      prompt("Sorry! Please enter '#{MARKER_1}' or '#{MARKER_2}'")
    end
    prompt("")
    prompt("Great! You'll be an #{choice}.")
    assign_markers(choice)
  end

  def select_player_name
    human.select_name
  end

  # rubocop:disable Layout/LineLength
  def display_first_player_message
    prompt("")
    prompt("You'll go first during the initial round\nand alterate with #{computer.name} for each subsequent round.")
    prompt("")
    display_continue_message
  end
  # rubocop:enable Layout/LineLength

  def assign_markers(human_choice)
    human.marker = human_choice

    computer.marker = if human.marker == MARKER_1
                        MARKER_2
                      else
                        MARKER_1
                      end
  end

  def play_single_round
    loop do
      current_player_moves
      break if board.someone_won_round? || board.full?
      clear_screen_and_display_board if human_turn?
    end
  end

  def play_until_max_rounds
    loop do
      clear_screen_and_display_board
      play_single_round
      display_round_result
      update_score
      display_score
      break if someone_won_game?
      display_continue_message
      reset_round
    end
  end

  def main_game
    loop do
      play_until_max_rounds
      display_game_winner
      break unless play_again?
      display_play_again_message
      reset_game
    end
  end

  def clear_screen_and_display_board
    clear
    display_board
  end

  # rubocop:disable Layout/LineLength
  def display_board
    prompt("You're an #{human.marker}. #{computer.name} is an #{computer.marker}")
    prompt("")
    prompt("#{display_first_to_move} goes first this round!")
    prompt("")
    board.draw
    prompt("")
  end
  # rubocop:enable Layout/LineLength

  def current_player_moves
    human_turn? ? human_moves : computer_moves
    update_current_player
  end

  def update_current_player
    @current_player = if human_turn?
                        :computer_player
                      else
                        :human_player
                      end
  end

  def human_turn?
    @current_player == :human_player
  end

  def human_moves
    str_number = nil
    prompt("Please choose an available square (#{joinor(board.unmarked_keys)})")
    loop do
      str_number = gets.chomp
      break if valid_choice?(str_number)
      prompt(MESSAGE["invalid_choice"])
    end

    board[str_number.to_i] = human.marker
  end

  def valid_choice?(str_number)
    if str_number.include?(".") || str_number.start_with?("0")
      false
    elsif board.unmarked_keys.include?(str_number.to_i)
      true
    else
      false
    end
  end

  def computer_moves
    if computer.detect_winning_square(board, computer)
      select_winning_square
    elsif computer.detect_blocking_square(board, human)
      select_blocking_square
    elsif computer.middle_square_available?(board, 5)
      select_middle_square
    else
      select_random_square
    end
  end

  def select_winning_square
    win = computer.detect_square(board, computer)
    computer.select_square(win, board)
  end

  def select_blocking_square
    block = computer.detect_square(board, human)
    computer.select_square(block, board)
  end

  def select_middle_square
    middle = 5
    computer.select_square(middle, board)
  end

  def select_random_square
    random = board.unmarked_keys.sample
    computer.select_square(random, board)
  end

  def display_round_result
    clear_screen_and_display_board

    case board.winning_marker
    when human.marker then prompt("#{human.name} won!")
    when computer.marker then prompt("#{computer.name} won!")
    else prompt("Board is full. It's a tie!")
    end
  end

  def update_score
    winning_mark = board.winning_marker
    if human.marker == winning_mark
      score.tally[human] += 1
    elsif computer.marker == winning_mark
      score.tally[computer] += 1
    end
  end

  def display_score
    prompt("")
    prompt(MESSAGE["score"])
    prompt("#{human.name}: #{score.display(human)}")
    prompt("#{computer.name}: #{score.display(computer)}")
    prompt("")
  end

  def someone_won_game?
    !!score.detect_game_winner
  end

  def reset_game
    board.reset
    @@first_to_move = :human_player
    @current_player = @@first_to_move
    clear
    score.reset
  end

  def display_game_winner
    game_winner = score.detect_game_winner
    prompt(MESSAGE["game_over"])
    prompt("That's #{Score::MAX_ROUNDS} rounds for #{game_winner.name}.")
    prompt("#{game_winner.name} wins the game!")
    prompt("")
  end

  def reset_round
    board.reset
    update_first_to_move
    clear
  end

  def display_first_to_move
    if @@first_to_move == :human_player
      human.name
    else
      computer.name
    end
  end

  def update_first_to_move
    @@first_to_move = if @@first_to_move == :human_player
                        :computer_player
                      else
                        :human_player
                      end
    @current_player = @@first_to_move
  end
end

new_game = TTTGame.new
new_game.play
