require "sinatra"
require "sinatra/reloader"

get "/" do
  root = File.expand_path("..", __FILE__)
  @files = Dir.glob(root + "/data/*").map do |absolute_path|
    File.basename(absolute_path)
  end
  erb(:index)
end