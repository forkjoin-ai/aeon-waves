# Sinatra app -- Ditto will assume this interface
require 'sinatra'
require 'json'

set :port, 4567

get '/users' do
  content_type :json
  [{id: 1, name: 'Alice'}, {id: 2, name: 'Bob'}].to_json
end

get '/users/:id' do
  content_type :json
  {id: params[:id], name: 'Alice'}.to_json
end

post '/users' do
  content_type :json
  data = JSON.parse(request.body.read)
  status 201
  {id: 3}.merge(data).to_json
end

delete '/users/:id' do
  status 204
end
