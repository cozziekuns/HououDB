# encoding: UTF-8

require_relative 'parser.rb'
require_relative 'model.rb'
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
    @db = Sequel.connect('postgres://localhost/hououdb')
  end

  def log_visited?(hanchan_log)
    return !!@db[:hanchan].where(tenhou_log: hanchan_log.url).first
  end

  def generate_raw_uri(log_uri)
    raw_uri = log_uri.gsub("?log=") {"mjlog2xml.cgi?"}
    raw_uri.gsub("http") { "https" }
  end

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

    parser = LogParser.new(log_body)
    process_blob(hanchan_log, parser.get_stat_blob)
  end

  def process_blob(hanchan_log, stat_blob)
    hanchan = Model_Hanchan.new

    hanchan_log.players.each_with_index { |player, placement|
      # Get or create player id
      player_model = @db[:players].where(username: player).first
      if not player_model
        player_id = @db[:players].insert(username: player)
      else
        player_id = player_model[:id]
      end

      seat = stat_blob[:player_seats][placement]

      hanchan.add_player(
        player_id,
        placement,
        seat,
        stat_blob[:player_dan][seat],
        stat_blob[:player_ratings][seat],
        stat_blob[:player_scores][seat],
      )
    }

    hanchan.time_start = hanchan_log.timestamp
    hanchan.average_rating = stat_blob[:avg_rating]
    hanchan.tenhou_log = hanchan_log.url
    
    hanchan.players.each { |hanchan_player|
      hanchan_player.commit_to_db(@db)
    }

    hanchan_id = hanchan.commit_to_db(@db)

    hanchan.players.each { |hanchan_player| 
      hanchan_player.commit_hanchan_id(@db, hanchan_id)
    }

    stat_blob[:hand_results].each { |hand_result| 
      hand_result_model = Model_HandResult.new(hand_result)
      hand_result_model.hanchan_id = hanchan_id

      hand_result_model.commit_to_db(@db)
    }
    exit
  end

  def run
    log_archive_filenames.each { |log_archive_filename|
      puts "--------------------------------------"
      puts "Begin parsing: #{log_archive_filename}"
      puts "--------------------------------------"
      next unless log_archive_filename["scc2019032206"]
      get_hanchan_logs(log_archive_filename).each { |hanchan_log|
        next if log_visited?(hanchan_log)
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