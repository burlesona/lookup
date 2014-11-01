require 'sinatra/base'
require 'sinatra/json'
require 'json'
require 'slim'
require_relative './initializer'

class App < Sinatra::Base
  set :views, settings.root + '/templates'

  get '/' do
    slim :lookup
  end

  get '/lookup' do
    data = Geocoder.search([params[:address],params[:zip]].join(', ')).first
    coord = data.geometry["location"]
    @neighborhood = Neighborhood.with_point(coord["lat"],coord["lng"])
    json @neighborhood
  end

  get '/neighborhoods/?' do
    @ndata = Neighborhood.order(:id).to_json
    slim :neighborhoods
  end

  post '/neighborhoods' do
    @neighborhood = Neighborhood.new request_data
    if @neighborhood.save
      json @neighborhood
    else
      500
    end
  end

  put '/neighborhoods/:id' do
    @neighborhood = Neighborhood.find(params[:id])
    if @neighborhood.update_attributes(request_data)
      json @neighborhood
    else
      500
    end
  end

  delete '/neighborhoods/:id' do
    @neighborhood = Neighborhood.find(params[:id])
    @neighborhood.destroy
    204
  end

  def request_data
    request.body.rewind
    JSON.parse request.body.read, symbolize_names: true
  end
end
