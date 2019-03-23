require 'sinatra'
require 'sinatra/reloader' if development?
require 'sequel'
require 'haml'

DB = Sequel.connect('postgres://localhost/hououdb')

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
          (east_player_id =~ player_id) | 
          (south_player_id =~ player_id) | 
          (west_player_id =~ player_id) | 
          (north_player_id =~ player_id)
        }
      end
    end
  }

  p query.all.size

  # DB[:players].where(username: '').get(:id)
  return params.to_s
end

# id = DB[:players].where(username: 'liebe').get(:id)
# "Hello World! " + id.to_s
