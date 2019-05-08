require 'nokogiri'

#==============================================================================
# ** Game_Hand
#==============================================================================

class Game_Hand

  attr_reader   :tiles

  def initialize
    @tiles = []
  end

  def refresh(haipai)
    @tiles = haipai
    @tiles.sort!
  end

  def draw(tile)
    @tiles.push(tile)
    @tiles.sort!
  end

  def discard(tile)
    @tiles.delete(tile)
    @tiles.sort!
  end

end

#==============================================================================
# ** Game_HanchanPlayer
#==============================================================================

class Game_HanchanPlayer

  attr_reader   :hand
  attr_reader   :seat
  attr_accessor :player_id
  attr_accessor :dan
  attr_accessor :rating
  attr_accessor :placement
  attr_accessor :score

  def initialize(hanchan_id, seat)
    @hanchan_id = hanchan_id
    @player_id = nil
    @seat = seat
    @dan = 0
    @rating = 0
    @hand = Game_Hand.new
    @score = 0
    @placement = 0
  end

  def payload
    return {
      hanchan_id: @hanchan_id,
      player_id: @player_id,
      seat: @seat,
      dan: @dan,
      rating: @rating,
      score: @score,
      placement: @placement,
    }
  end

end

#==============================================================================
# ** Game_HandResult
#==============================================================================

class Game_HandResult

  attr_reader   :round
  attr_accessor :scores
  attr_accessor :honba
  attr_accessor :riichi_sticks
  attr_accessor :dora
  attr_accessor :result_type
  attr_accessor :winning_player
  attr_accessor :losing_player
  attr_accessor :fu
  attr_accessor :han
  attr_accessor :base_score
  attr_accessor :is_oras

  def initialize(hanchan_id, round)
    @hanchan_id = hanchan_id
    @round = round
    @scores = [0, 0, 0, 0]
    @honba = 0
    @riichi_sticks = 0
    @dora = 0
    @result_type = 0
    @winning_player = nil
    @losing_player = nil
    @fu = 0
    @han = 0
    @base_score = 0
    @is_oras = false
  end

  def payload
    return {
      hanchan_id: @hanchan_id,
      round: @round,
      honba: @honba,
      riichi_sticks: @riichi_sticks,
      east_player_score: @scores[0],
      south_player_score: @scores[1],
      west_player_score: @scores[2],
      north_player_score: @scores[3],
      result_type: @result_type,
      han: @han,
      fu: @fu,
      base_score: @base_score,
      winning_player: @winning_player,
      losing_player: @losing_player,
      is_oras: @is_oras,
    }
  end

end

#==============================================================================
# ** Game_HandEvent
#==============================================================================

class Game_HandEvent

  def initialize(type)
    @type = type
  end

end

#==============================================================================
# ** Game_Hanchan
#==============================================================================

class Game_Hanchan

  def initialize(hanchan_id, player_ids)
    @db = nil
    @hanchan_id = hanchan_id
    @player_ids = player_ids
    @hand_events = []
    @hand_results = []
    init_hanchan_players
  end

  def init_hanchan_players
    @hanchan_players = 0.upto(3).map { |seat| 
      Game_HanchanPlayer.new(@hanchan_id, seat) 
    }
  end

  def parse(log_body)
    @xml = Nokogiri::XML(log_body)
    @xml.root.traverse { |node| parse_node(node) }

    return {
      hanchan_players: @hanchan_players,
      hand_results: @hand_results, 
    }
  end

  def parse_node(node)
    case node.name
    when 'UN'
      parse_un_node(node)
    when 'INIT'
      parse_init_node(node)
    when /\A[TUVW]\d+\Z/
      parse_draw_node(node)
    when /\A[DEFG]\d+\Z/
      parse_discard_node(node)
    when 'AGARI'
      parse_agari_node(node)
    when 'RYUUKYOKU'
      parse_ryuukyoku_node(node)
    end
  end

  def parse_un_node(node)
    # For whatever reason, Tenhou logs disconnects as a UN-node.
    return if not node.attributes['dan'] or not node.attributes['rate']

    node.attributes['dan'].value.split(',').each_with_index { |dan, i| 
      @hanchan_players[i].dan = dan
    }

    node.attributes['rate'].value.split(',').each_with_index { |rating, i|
      @hanchan_players[i].rating = rating
    }
  end

  def parse_init_node(node)
    seed = node.attributes['seed'].value.split(',').map { |s| s.to_i }
    round = seed[0]

    0.upto(3).each { |i| 
      @hanchan_players[i].hand.refresh(
        node.attributes["hai#{i}"].value.split(',').map { |s| s.to_i }
      )
    }

    hand_result = Game_HandResult.new(@hanchan_id, round)
    hand_result.honba = seed[1]
    hand_result.riichi_sticks = seed[2]
    hand_result.dora = seed[5]
    hand_result.scores = node.attributes['ten'].value.split(',').map { |s| s.to_i * 100 }

    @hand_results.push(hand_result)
  end

  def parse_draw_node(node)
    seat = ('T'.ord - node.name[0].ord).abs
    @hanchan_players[seat].hand.draw(node.name[1..-1].to_i)
  end

  def parse_discard_node(node)
    seat = ('D'.ord - node.name[0].ord).abs
    @hanchan_players[seat].hand.discard(node.name[1..-1].to_i)
  end

  def parse_agari_node(node)
    hand_result = @hand_results[-1]

    if node.attributes['yaku']
      yaku = node.attributes['yaku'].value.split(',').map { |s| s.to_i }
    elsif node.attributes['yakuman']
      yaku = node.attributes['yakuman'].value.split(',').map { |s| [s.to_i, 13] }.flatten
    else
      puts node
      puts "What the poop is this!!!"
      raise Exception
    end
    score = node.attributes['ten'].value.split(',').map { |s| s.to_i }
  
    winning_player = node.attributes['who'].value.to_i
    losing_player = node.attributes['fromWho'].value.to_i

    hand_result.winning_player = winning_player
    if winning_player == losing_player
      hand_result.result_type = 0
      hand_result.losing_player = nil
    else
      hand_result.result_type = 1
      hand_result.losing_player = losing_player
    end

    total_han = 0
    yaku.each_with_index { |han, i| 
      next if i % 2 == 0
      total_han += han
    }

    hand_result.han = total_han
    hand_result.fu = score[0]
    hand_result.base_score = score[1]

    parse_owari_node(node) if node.attributes['owari']
  end

  def parse_ryuukyoku_node(node)
    hand_result = @hand_results[-1]

    hand_result.result_type = 2
    hand_result.winning_player = nil
    hand_result.losing_player = nil
    hand_result.han = 0
    hand_result.fu = 0
    hand_result.base_score = 0

    parse_owari_node(node) if node.attributes['owari']
  end

  def parse_owari_node(node)
    placements = []

    node.attributes['owari'].value.split(",").map { |s| s.to_i }.each_with_index { |score, i|
      next if i % 2 == 1
      @hanchan_players[i / 2].score = score * 100
      placements.push(score)
    }

    placements = placements.sort.reverse

    @hanchan_players.each { |hanchan_player|
      hanchan_player.placement = placements.index(hanchan_player.score / 100)
      hanchan_player.player_id = @player_ids[hanchan_player.placement]
      # Hack to fix tiebreaker scenarios
      placements[hanchan_player.placement] = nil
    }

    @hand_results[-1].is_oras = true
  end

end

# For debugging purposes only

__END__

File.open('test_log', 'r+') { |f| 
  log_body = f.read

  hanchan = Game_Hanchan.new(nil, [1, 2, 3, 4])
  hanchan.parse(log_body)
}