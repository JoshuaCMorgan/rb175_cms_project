require "sinatra"
require "sinatra/reloader"

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
  erb(:index)
end

def error_for_filename(filename)
  return "#{filename} does not exist" unless @files.include?(filename)
  false
end

# View contents of document
get "/:filename" do 
  filename = params[:filename].strip
  
  error = error_for_filename(filename)
  if error
    session[:error] = error
    redirect "/"
  else
    file_path = @root + "/data/" + filename
    headers["Content-Type"] = "text/plain"
    File.read(file_path)
  end
end

