require 'net/http'
require 'zlib'

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
  response.body.scan(/(scc\d+\.html\.gz)/) { |match| 
    filenames.push(match[0])
  }

  return filenames
end

def log_urls(log_archive_filename)
  log_urls = []

  raw_url = 'https://tenhou.net/sc/raw/dat/' + log_archive_filename
  response = Net::HTTP.get(URI(raw_url))

  body = Zlib::GzipReader.new(StringIO.new(response)).read

  # Need to capture player names somewhere here; might want to do 
  # something for each line?

  body.scan(/"(http:\/\/tenhou.net.+)"/) { |match| 
    log_urls.push(match[0].gsub(/\/\d\//) { "\/3\/"} )
  }

  return log_urls
end

def get_log_body(log_url)
  request_uri = URI(log_url)

  raw_uri = log_url.gsub("?log=") {"mjlog2xml.cgi?"}
  raw_uri.gsub("http") { "https" }

  request = Net::HTTP::Get.new(log_uri)
  request['origin'] = 'http://tenhou.net'
  request['referer'] = log_url

  response = Net::HTTP.start(request_uri.hostname, request_uri.port) { |http| 
    http.request(request) 
  }

  return response.body
end

def parse_body(log_body)
  # parse MJ log
end

#-----------------------------------------------------------------------------
# * Main
#-----------------------------------------------------------------------------

log_archive_filenames.each { |log_archive_filename|
  log_urls.each { |log_url| 
    next if log_visited?(log_url)
    parse_body(get_log_body(log_url)) 
  }
}