require "sinatra"
require "sinatra/reloader"

before do
  @root = File.expand_path("..", __FILE__)

  @files = Dir.glob(@root + "/data/*").map do |path|
    File.basename(path)
  end
end




# Display document titles
get "/" do
  p ENV.keys
  erb(:index)
end

# View contents of document
get "/:filename" do 
  file_path = @root + "/data/" + params[:filename]

  headers["Content-Type"] = "text/plain"
  File.read(file_path)
end