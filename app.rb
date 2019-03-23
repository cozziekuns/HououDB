require 'sinatra'
require 'sinatra/reloader' if development?
require 'sequel'
require 'haml'

DB = Sequel.connect('postgres://localhost/hououdb')

def get_player_name(player_id)
  DB[:players].where(id: player_id).get(:username)
end

def get_formatted_timestamp(timestamp)
  return timestamp.to_s.split(" ")[0...2].join(" ") 
end

get '/' do
  haml :index
end

get '/search' do
  query = DB[:hanchan]

  params.keys.each { |key|
    if key[/player-\d+/]
      player_id = DB[:players].where(username: params[key]).get(:id)
      if player_id
        query = query.where{
          (east_player_id =~ player_id) | (south_player_id =~ player_id) | 
          (west_player_id =~ player_id) | (north_player_id =~ player_id)
        }
      else
        # TODO: Player not found.
        query = query.where{east_player_id =~ -1}
      end
    end
  }

  @hanchan_ary = []

  query.all.each { |hanchan|
    formatted_hanchan = {}

    formatted_hanchan[:rating] = hanchan[:avg_rating].to_s
    formatted_hanchan[:timestamp] = get_formatted_timestamp(hanchan[:time_start])
    formatted_hanchan[:east_player_name] = get_player_name(hanchan[:east_player_id])
    formatted_hanchan[:south_player_name] = get_player_name(hanchan[:south_player_id])
    formatted_hanchan[:west_player_name] = get_player_name(hanchan[:west_player_id])
    formatted_hanchan[:north_player_name] = get_player_name(hanchan[:north_player_id])
    formatted_hanchan[:tenhou_log] = hanchan[:tenhou_log]

    @hanchan_ary.push(formatted_hanchan)
  }

  haml :search_results
end
