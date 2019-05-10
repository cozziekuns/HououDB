require 'sinatra'
require 'sinatra/json'
require 'sinatra/reloader' if development?
require 'sequel'

DB = Sequel.connect(ENV['DATABASE_URL'] || 'postgres://localhost/hououdb')

def get_hanchan_player(hanchan_player_id)
  return DB[:hanchan_players].first(id: hanchan_player_id)
end

def get_formatted_timestamp(timestamp)
  return timestamp.to_s.split(" ")[0...2].join(" ") 
end

def get_average_rating(hanchan_id)
  DB[:hanchan_players].where(hanchan_id: hanchan_id).avg(:rating)
end

get '/' do
  'Hello World'
end

get '/liebe' do
  response = {}

  response[:hanchan] = []

  DB[:hanchan_players].where(username: 'liebe').map(:id).each { |hanchan_player_id|
    DB[:hanchan].where{
      (east_hanchan_player_id =~ hanchan_player_id) | 
      (south_hanchan_player_id =~ hanchan_player_id) | 
      (west_hanchan_player_id =~ hanchan_player_id) | 
      (north_hanchan_player_id =~ hanchan_player_id)
    }.each { |hanchan| 
      formatted_hanchan = {}

      formatted_hanchan[:rating] = get_average_rating(hanchan[:id])
      formatted_hanchan[:timestamp] = get_formatted_timestamp(hanchan[:time_start])

      formatted_hanchan[:players] = ['east', 'south', 'west', 'north'].map { |wind_str| 
        (wind_str + '_hanchan_player_id').to_sym
      }.map { |sym|
        get_hanchan_player(hanchan[sym])
      }

      formatted_hanchan[:tenhou_log] = hanchan[:tenhou_log]

      response[:hanchan].push(formatted_hanchan)
    }
  }

  json(response)
end
