require 'sinatra'
require 'sequel'
require 'haml'

DB = Sequel.connect('postgres://localhost/hououdb')

get '/' do
  haml :index
end

# id = DB[:players].where(username: 'liebe').get(:id)
# "Hello World! " + id.to_s
