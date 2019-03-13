# encoding: UTF-8

require_relative "parser.rb"
require 'net/http'
require 'zlib'

#==============================================================================
# ** Batch_TenhouLog
#==============================================================================

class Batch_TenhouLog

  def initialize
    @players = []
  end

  def log_visited?(log_url)
    # Eventually this will be a DB check? To see if the logs have been parsed.
    return false
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

  def log_urls(log_archive_filename)
    log_urls = []

    raw_url = 'https://tenhou.net/sc/raw/dat/' + log_archive_filename
    response = Net::HTTP.get(URI(raw_url))

    body = Zlib::GzipReader.new(StringIO.new(response)).read

    body.split("<br>").each { |line|
      # For now, we're only going to get the stats for Hanchan.
      next if not line["四鳳南喰赤"]

      @players = line.split("|")[-1].split(" ")
      @players.map! { |s| s.gsub(/\(.+\)/) { "" } }

      line.scan(/"(http:\/\/tenhou.net.+)"/) { |match| 
        log_urls.push(match[0].gsub(/\/\d\//) { "\/3\/"} )
      }
    }

    return log_urls
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

  def parse_body(log_body)
    parser = LogParser.new(log_body)
    process_blob(parser.get_stat_blob)
    exit
  end

  def process_blob(stat_blob)
    @players.each_with_index { |player, i| 
      p [player, stat_blob[:player_seats][i]]
    }
  end

  def run
    log_archive_filenames.each { |log_archive_filename|
      log_urls(log_archive_filename).each { |log_url| 
        next if log_visited?(log_url)
        parse_body(get_log_body(log_url)) 
      }
    }
  end

end

#-----------------------------------------------------------------------------
# * Main
#-----------------------------------------------------------------------------

batch = Batch_TenhouLog.new
batch.run