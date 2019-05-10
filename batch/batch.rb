# encoding: UTF-8

require_relative 'game.rb'
require 'net/http'
require 'zlib'

require 'sequel'

SAVE_LOG_FILE = true

#==============================================================================
# ** Log_Hanchan
#==============================================================================

class Log_Hanchan

  attr_reader   :url
  attr_reader   :players
  attr_reader   :timestamp

  def initialize(url, players, timestamp)
    @url = url
    @players = players
    @timestamp = timestamp
  end

end

#==============================================================================
# ** Batch_TenhouLog
#==============================================================================

class Batch_TenhouLog

  def initialize
    init_database_connection
  end

  def init_database_connection
    @db = Sequel.connect(ENV['DATABASE_URL'] || 'postgres://localhost/hououdb')
  end

  def log_visited?(hanchan_log)
    return !!@db[:hanchan].where(tenhou_log: hanchan_log.url).first
  end

  def generate_raw_uri(log_uri)
    raw_uri = log_uri.gsub("?log=") {"mjlog2xml.cgi?"}
    raw_uri.gsub("http") { "https" }
  end

  #---------------------------------------------------------------------------
  # * ORM Helper Methods
  #---------------------------------------------------------------------------

  def upsert_hanchan(hanchan_log)
    return @db[:hanchan].insert({
      tenhou_log: hanchan_log.url,
      time_start: hanchan_log.timestamp
    })
  end

  def upsert_hanchan_players(hanchan_players)
    hanchan_player_ids = []

    hanchan_players.each { |hanchan_player|
      hanchan_player_id = @db[:hanchan_players].insert(hanchan_player.payload)
      hanchan_player_ids.push(hanchan_player_id)
    }

    return hanchan_player_ids
  end

  def update_hanchan_with_player_ids(hanchan_id, hanchan_player_ids)
    payload = {}

    hanchan_player_fields = [
      :east_hanchan_player_id,
      :south_hanchan_player_id,
      :west_hanchan_player_id,
      :north_hanchan_player_id
    ]

    hanchan_player_ids.each_with_index { |player_id, i| 
      payload[hanchan_player_fields[i]] = player_id
    }

    @db[:hanchan].where(id: hanchan_id).update(payload)
  end

  def upsert_hand_results(hand_results)
    hand_result_ids = []
    
    hand_results.each { |hand_result| 
      hand_result_id = @db[:hand_results].insert(hand_result.payload)
      hand_result_ids.push(hand_result)
    }

    return hand_result_ids
  end

  #---------------------------------------------------------------------------
  # * Log Scraping Methods
  #---------------------------------------------------------------------------

  def log_archive_filenames
    filenames = []

    response = Net::HTTP.get(URI('https://tenhou.net/sc/raw/list.cgi'))
    response.scan(/(scc\d+\.html\.gz)/) { |match| filenames.push(match[0]) }

    return filenames
  end

  def get_hanchan_logs(log_archive_filename)
    hanchan_logs = []

    raw_url = 'https://tenhou.net/sc/raw/dat/' + log_archive_filename
    response = Net::HTTP.get(URI(raw_url))

    body = Zlib::GzipReader.new(StringIO.new(response)).read
    body.split("<br>").each { |line|
      # TODO: For now, we're only going to get the stats for Hanchan.
      next if not line["四鳳南喰赤"]

      log_url = nil
      line.scan(/"(http:\/\/tenhou.net.+)"/) { |match| 
        log_url = match[0].gsub(/\/\d\//) { "\/3\/"}
      }

      player_names = line.split("|")[-1].split(" ")
      player_names.map! { |s| s.gsub(/\([+-]?\d+\.\d\)/) { "" } }

      # TODO: Figure out what time zone this stuff is
      timestamp = nil
      hour, minute = line.split("|")[0].strip.split(":").map { |s| s.to_i }
      log_url.scan(/log=(\d+)/) { |match| 
        tenhou_timestamp = match[0]

        year = tenhou_timestamp[0...4]
        month = tenhou_timestamp[4...6]
        day = tenhou_timestamp[6...8]

        timestamp = Time.new(year=year, month=month, day=day, hour=hour, minute=minute)
      }   
      
      hanchan_logs.push(Log_Hanchan.new(log_url, player_names, timestamp))
    }

    return hanchan_logs
  end

  def get_log_body(log_url)
    @log_raw_url = log_url

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

  def parse_log_body(hanchan_log)
    log_body = get_log_body(hanchan_log.url)

    hanchan_id = upsert_hanchan(hanchan_log)
    puts "--------------------------------------"
    puts " Created new Hanchan ID#{hanchan_id}"
    puts "--------------------------------------"

    hanchan = Game_Hanchan.new(hanchan_id)
    results = hanchan.parse(log_body)

    upsert_hand_results(results[:hand_results])

    results[:hanchan_players].each { |hanchan_player|
      hanchan_player.username = hanchan_log.players[hanchan_player.placement]
    }

    hanchan_player_ids = upsert_hanchan_players(results[:hanchan_players])
    update_hanchan_with_player_ids(hanchan_id, hanchan_player_ids)
  end

  def run
    log_archive_filenames.each { |log_archive_filename|
      puts "--------------------------------------"
      puts "Begin parsing: #{log_archive_filename}"
      puts "--------------------------------------"
      get_hanchan_logs(log_archive_filename).each { |hanchan_log|
        next if log_visited?(hanchan_log)
        puts "Begin parsing: #{hanchan_log.url}"
        parse_log_body(hanchan_log)
        puts "Finished parsing: #{hanchan_log.url}"
      }
      puts "--------------------------------------"
      puts "Finished parsing: #{log_archive_filename}"
      puts "--------------------------------------"
    }
  end

end

#-----------------------------------------------------------------------------
# * Main
#-----------------------------------------------------------------------------

Batch_TenhouLog.new.run