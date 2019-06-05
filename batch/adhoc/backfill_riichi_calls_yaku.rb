# encoding: UTF-8

require_relative '../game.rb'
require 'net/http'

require 'sequel'

#==============================================================================
# ** Batch_BackfillHandResults
#==============================================================================

class Batch_BackfillHandResults

  def initialize
    init_database_connection
  end

  def init_database_connection
    @db = Sequel.connect(ENV['DATABASE_URL'] || 'postgres://localhost/hououdb')
  end

  def get_log_body(log_url)
    request_uri = URI(log_url)

    raw_uri = log_url.gsub("?log=") {"mjlog2xml.cgi?"}
    raw_uri.gsub("http") { "https" }

    request = Net::HTTP::Get.new(raw_uri)
    request['origin'] = 'http://tenhou.net'
    request['referer'] = log_url

    response = Net::HTTP.start(request_uri.hostname, request_uri.port) { |http| 
      http.request(request) 
    }

    return response.body
  end

  def parse_log_body(hanchan_log, hanchan_id)
    hanchan = Game_Hanchan.new(hanchan_id)
    results = hanchan.parse(hanchan_log)

    update_hand_results(results[:hand_results], hanchan_id)
  end

  def update_hand_results(hand_results, hanchan_id)
    hand_results.each { |hand_result|
      hand_result = @db[:hand_results].where(
        hanchan_id: hanchan_id,
        round: hand_result.round,
        honba: hand_result.honba
      ).update(
        riichi: hand_result.riichi,
        naki: hand_result.naki,
        yaku: hand_result.yaku,
      )
    }
  end

  def run
    @db[:hanchan].where{ id > 7074 }.each { |hanchan| 
      log_body = get_log_body(hanchan[:tenhou_log])
      parse_log_body(log_body, hanchan[:id])
      puts "Finished backfill for HanchanID: #{hanchan[:id]}"
    }
  end

end

#-----------------------------------------------------------------------------
# * Main
#-----------------------------------------------------------------------------

Batch_BackfillHandResults.new.run