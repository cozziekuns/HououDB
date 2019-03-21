require 'nokogiri'

#==============================================================================
# ** LogParser
#==============================================================================

class LogParser

  def initialize(log_body)
    @xml = Nokogiri::XML(log_body)
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

  def get_average_rating
    str = @xml.xpath('//UN').first.attributes['rate'].value

    ratings = str.split(',').map { |s| s.to_f }
    return (ratings.inject(:+) / ratings.length).to_i
  end

  def get_stat_blob
    blob = {}
    blob[:player_seats] = get_player_seats
    blob[:avg_rating] = get_average_rating

    return blob
  end

end