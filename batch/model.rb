#==============================================================================
# ** Model_Hanchan
#==============================================================================

class Model_Hanchan

  attr_reader   :players
  attr_accessor :tenhou_log
  attr_accessor :time_start
  attr_accessor :average_rating

  def initialize
    @time_start = nil
    @players = Array.new(4)
    @avg_rating = 0
    @tenhou_log = nil
  end

  def add_player(player_id, placement, seat, dan, rating, score)
    @players[seat] = Model_HanchanPlayer.new(player_id, placement, seat, dan, rating, score)
  end

  def commit_to_db(session_db)
    return session_db[:hanchan].insert(commit_payload)
  end

  def commit_payload
    return {
      time_start: @time_start,
      east_hanchan_player_id: @players[0].id,
      south_hanchan_player_id: @players[1].id,
      west_hanchan_player_id: @players[2].id,
      north_hanchan_player_id: @players[3].id,
      avg_rating: @average_rating,
      tenhou_log: @tenhou_log,
    }
  end

end

#==============================================================================
# ** Model_HanchanPlayer
#==============================================================================

class Model_HanchanPlayer

  attr_reader   :id

  def initialize(player_id, placement, seat, dan, rating, score)
    @id = nil
    @player_id = player_id
    @placement = placement
    @seat = seat
    @dan = dan
    @rating = rating
    @score = score
  end

  def commit_hanchan_id(session_db, hanchan_id)
    session_db[:hanchan_players].where(id: @id).update(hanchan_id: hanchan_id)
  end

  def commit_to_db(session_db)
    @id = session_db[:hanchan_players].insert(commit_payload)
    return @id
  end

  def commit_payload
    return {
      player_id: @player_id,
      placement: @placement,
      seat: @seat,
      dan: @dan,
      rating: @rating,
      score: @score
    }
  end

end

#==============================================================================
# ** Model_HandResult
#==============================================================================

class Model_HandResult

  attr_reader   :id
  attr_accessor :hanchan_id

  def initialize(hanchan_result)
    @id = nil
    @hanchan_id = nil
    @round = hanchan_result[:round]
    @honba = hanchan_result[:honba]
    @riichi_sticks = hanchan_result[:riichi_sticks]
    @east_player_score = hanchan_result[:east_player_score]
    @south_player_score = hanchan_result[:south_player_score]
    @west_player_score = hanchan_result[:west_player_score]
    @north_player_score = hanchan_result[:north_player_score]
    @result_type = hanchan_result[:result_type]
    @winning_player = hanchan_result[:winning_player]
    @losing_player = hanchan_result[:losing_player]
    @han = hanchan_result[:han]
    @fu = hanchan_result[:fu]
    @base_score = hanchan_result[:base_score]
  end

  def commit_to_db(session_db)
    @id = session_db[:hand_results].insert(commit_payload)
    return @id
  end

  def commit_payload
    return {
      hanchan_id: @hanchan_id,
      round: @round,
      honba: @honba,
      riichi_sticks: @riichi_sticks,
      east_player_score: @east_player_score,
      south_player_score: @south_player_score,
      west_player_score: @west_player_score,
      north_player_score: @north_player_score,
      result_type: @result_type,
      winning_player: @winning_player,
      losing_player: @losing_player,
      han: @han,
      fu: @fu,
      base_score: @base_score,
    }
  end

end