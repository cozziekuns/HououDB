require 'sinatra'
require 'sinatra/cors'
require 'sinatra/json'
require 'sinatra/reloader' if development?
require 'sequel'

set :allow_origin, "*"
set :allow_methods, "GET"

DB = Sequel.connect(ENV['DATABASE_URL'] || 'postgres://localhost/hououdb')

# TODO: Move these getter methods into another file

def get_hanchan_player(hanchan_player_id)
  return DB[:hanchan_players].first(id: hanchan_player_id)
end

def get_formatted_timestamp(timestamp)
  return timestamp.to_s.split(" ")[0...2].join(" ") 
end

def get_average_rating(hanchan_id)
  DB[:hanchan_players].where(hanchan_id: hanchan_id).avg(:rating)
end

def player_id_to_hanchan_list(hanchan_player_ids)
  hanchan_list = []

  hanchan_player_ids.each { |hanchan_player_id|
    DB[:hanchan].where{
      (east_hanchan_player_id =~ hanchan_player_id) | 
      (south_hanchan_player_id =~ hanchan_player_id) | 
      (west_hanchan_player_id =~ hanchan_player_id) | 
      (north_hanchan_player_id =~ hanchan_player_id)
    }.each { |hanchan| 
      formatted_hanchan = {}

      formatted_hanchan[:id] = hanchan[:id]
      formatted_hanchan[:rating] = get_average_rating(hanchan[:id])
      formatted_hanchan[:timestamp] = get_formatted_timestamp(hanchan[:time_start])

      formatted_hanchan[:players] = ['east', 'south', 'west', 'north'].map { |wind_str| 
        (wind_str + '_hanchan_player_id').to_sym
      }.map { |sym|
        get_hanchan_player(hanchan[sym])
      }

      formatted_hanchan[:tenhou_log] = hanchan[:tenhou_log]

      hanchan_list.push(formatted_hanchan)
    }
  }

  return hanchan_list
end

def calculate_placements(player_query)
  placements = []

  player_query.group_and_count(:placement).each { |counts|
    placements[counts[:placement]] = counts[:count]
  }

  return placements
end

get '/' do
  'Hello World'
end

get '/liebe' do
  response = {}

  player_query = DB[:hanchan_players].where(username: 'liebe')

  response[:hanchan] = player_id_to_hanchan_list(player_query.map(:id))
  response[:placements] = calculate_placements(player_query)

  json(response)
end

get '/player/:name/profile' do |username|
  response = {}

  player_query = DB[:hanchan_players].where(username: username)
  player_info = player_query.order(:id).last

  # TODO: implement actual stable dan formula
  response[:dan] = player_info[:dan]
  response[:rating] = player_info[:rating].round
  response[:stable_dan] = 8.3
  response[:total_games] = player_query.count

  json(response)
end

get '/player/:name/match_history' do |username|
  response = {}

  player_query = DB[:hanchan_players]
    .where(username: username)
    .order(Sequel.desc(:id))
    .limit(20)

  response[:hanchan] = player_id_to_hanchan_list(player_query.map(:id))

  json(response)
end