require "sinatra"
require "sinatra/reloader"
require "redcarpet"
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

# def render_markdown(text)
#   markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
#   markdown.render(text)
# end

def load_file_content(path)
  content = File.read(path)
  case File.extname(path)
  when ".txt"
    headers["Content-Type"] = "text/plain"
    content
  # when ".md"
  #   render_markdown(content)
  end
end

# Display document titles
get "/" do
  erb(:index)
end

# View contents of document
get "/:filename" do 
  file_path = @root + "/data/" + params[:filename]

  if File.file?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{params[:filename]} does not exit."
    redirect "/"
  end
end

