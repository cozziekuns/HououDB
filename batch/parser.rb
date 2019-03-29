require 'nokogiri'

#==============================================================================
# ** LogParser
#==============================================================================

class LogParser

  def initialize(log_body)
    @xml = Nokogiri::XML(log_body)
  end

  def oras_node
    return @xml.xpath('//INIT')[-1]
  end

  def terminal_node
    @xml.root.traverse { |node|
      return node if node.attributes.has_key?('owari')
    }
  end

  def get_player_seats
    results = [] 
    
    values = terminal_node.attributes['owari'].value
    values.split(",").each_with_index { |uma, i|
      next if i % 2 == 0
      results.push([uma.to_f, i / 2])
    }

    return results.sort { |a, b| b[0] <=> a[0] }.map { |ary| ary[1] }
  end

  def get_player_final_scores
    results = []

    values = terminal_node.attributes['owari'].value
    values.split(",").each_with_index { |score, i| 
      next if i % 2 == 1
      results.push(score.to_i * 100)
    }

    return results
  end

  def get_player_dan
    str = @xml.xpath('//UN').first.attributes['dan'].value
    return str.split(',').map { |s| s.to_i }
  end

  def get_player_ratings
    str = @xml.xpath('//UN').first.attributes['rate'].value
    return str.split(',').map { |s| s.to_f }
  end

  def get_average_rating
    str = @xml.xpath('//UN').first.attributes['rate'].value

    ratings = str.split(',').map { |s| s.to_f }
    return (ratings.inject(:+) / ratings.length).to_i
  end

  def get_hand_results
    hand_results = []
    current_hand = -1

    @xml.root.traverse { |node|
      if node.name == 'INIT'
        current_hand += 1
        hand_result = {}

        seed = node.attributes['seed'].value.split(",").map { |s| s.to_i }
        scores = node.attributes['ten'].value.split(",").map { |s| 100 * s.to_i }

        hand_result[:round] = seed[0]
        hand_result[:honba] = seed[1]
        hand_result[:riichi_sticks] = seed[2]

        hand_result[:east_player_score] = scores[0]
        hand_result[:south_player_score] = scores[1]
        hand_result[:west_player_score] = scores[2]
        hand_result[:north_player_score] = scores[3]

        hand_results[current_hand] = hand_result
      elsif node.name == 'AGARI'
        yaku = node.attributes['yaku'].value.split(',').map { |s| s.to_i }
        score = node.attributes['ten'].value.split(',').map { |s| s.to_i }

        winning_player = node.attributes['fromWho'].value.to_i
        losing_player = node.attributes['who'].value.to_i

        if winning_player == losing_player
          hand_results[current_hand][:result_type] = 0
          hand_results[current_hand][:winning_player] = winning_player
          hand_results[current_hand][:losing_player] = nil
        else
          hand_results[current_hand][:result_type] = 1
          hand_results[current_hand][:winning_player] = winning_player
          hand_results[current_hand][:losing_player] = losing_player
        end

        total_han = 0
        yaku.each_with_index { |han, i| 
          next if i % 2 == 0
          total_han += han
        }

        hand_results[current_hand][:han] = total_han
        hand_results[current_hand][:fu] = score[0]
        hand_results[current_hand][:base_score] = score[1]
      elsif node.name == 'RYUUKYOKU'
        hand_results[current_hand][:result_type] = 2
        hand_results[current_hand][:winning_player] = 0
        hand_results[current_hand][:losing_player] = 0
        hand_results[current_hand][:han] = 0
        hand_results[current_hand][:fu] = 0
        hand_results[current_hand][:base_score] = 0
      end
    } 
    
    return hand_results
  end

  def get_stat_blob
    blob = {}

    blob[:player_seats] = get_player_seats
    blob[:player_scores] = get_player_final_scores
    blob[:player_dan] = get_player_dan
    blob[:player_ratings] = get_player_ratings
    blob[:hand_results] = get_hand_results
    blob[:avg_rating] = get_average_rating

    return blob
  end

end