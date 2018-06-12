require "sinatra"
require "pg"
require_relative "./app/models/article"
require "sinatra/reloader"
require 'pry'
require 'csv'
require 'uri'

set :bind, '0.0.0.0'  # bind to all interfaces
set :views, File.join(File.dirname(__FILE__), "app", "views")

configure :development do
  set :db_config, { dbname: "news_aggregator_development" }
end

configure :test do
  set :db_config, { dbname: "news_aggregator_test" }
end

def db_connection
  begin
    connection = PG.connect(Sinatra::Application.db_config)
    yield(connection)
  ensure
    connection.close
  end
end

# Put your News Aggregator server.rb route code here

get "/" do
  redirect "/articles"
end

get "/articles" do
  @articles = db_connection { |conn| conn.exec("SELECT title, url, description FROM articles") }
  erb :"/articles"
end

get "/articles/new" do
  erb :new
end

post "/articles/new" do
  @title = params["article_title"]
  @description = params["article_description"]
  @url = params["article_url"]

  @error = nil
  if [@title, @description, @url].include?('')
    @error = "Please fill in all the fields!!!"
    erb :"/new"
  else
    db_connection do |conn|
      conn.exec_params("INSERT INTO articles (title, url, description) VALUES ($1, $2, $3)", [@title, @url, @description])
    end
    redirect "articles"
  end
end
