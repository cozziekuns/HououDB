require 'nokogiri'

#==============================================================================
# ** LogParser
#==============================================================================

class LogParser

  def initialize(log_body)
    @xml = Nokogiri::XML(log_body)
  end

  def get_player_seats
    terminal_node = @xml.xpath('//AGARI').select { |node| 
      node.attributes.has_key?('owari') 
    }.first
    
    results = [] 
    
    terminal_node.attributes['owari'].value.split(",").each_with_index { |uma, i|
      next if i % 2 == 0
      results.push([uma, i / 2])
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

def parse_body(log_body)
    blob = {}
    parsed_xml = Nokogiri::XML(log_body)

    blob['avg_rating'] = get_average_rating(parsed_xml)

    return blob
end