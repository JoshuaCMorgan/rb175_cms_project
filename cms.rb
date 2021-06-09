require "sinatra"
require "sinatra/reloader"
require 'pp'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  @root = File.expand_path("..", __FILE__)

  @files = Dir.glob(@root + "/data/*").map do |path|
    File.basename(path)
  end
end


# Display document titles
get "/" do
  puts 'Request headers:'
  puts request.env.class
  pp request.env
  'User agent: ' + request.env['HTTP_USER_AGENT']
  erb(:index)
end

def valid_filename?(filename)
  @files.include?(filename)
end

# View contents of document
get "/:filename" do 
  file_path = @root + "/data/" + params[:filename]
  
  if File.file?(file_path)
    headers["Content-Type"] = "text/plain"
    File.read(file_path)
  else
    session[:message] = "#{params[:filename]} does not exit."
    redirect "/"
  end
end

