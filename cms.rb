require "sinatra"
require "sinatra/reloader"
require "redcarpet"
require "yaml"

configure do
  enable :sessions
  set :session_secret, 'super secret'
end

def data_path  #  select a directory for data based on the environment the code is running in.
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

# def load_user_credentials
#   credential_path = If ENV["RACK_ENV"] == "test"
#     File.expand_path("../test/users.yaml",  __FILE__)
#   else
#     File.expand_path("../users.yaml",  __FILE__)
#   end
#   YAML.load_file(credential_path)
# end

def configuration_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test", __FILE__)
  else
    File.expand_path("..", __FILE__)
  end
end

def load_user_credentials
  config_path = File.join(configuration_path, "users.yml")
  YAML.load_file(config_path)
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_file_content(path)
  content = File.read(path)
  case File.extname(path)
  when ".txt"
    headers["Content-Type"] = "text/plain"
    content
  when ".md"
    render_markdown(content)
  end
end

def user_signed_in?
  session.key?(:username)
end

def require_signed_in_user
  unless user_signed_in?
    session[:message] = "You must be signed in to do that."
    redirect "/"
  end
end
# Display document titles
get "/" do
  pattern = File.join(data_path, "*")  # combines path segements using the correct path separator based on the current operating system.
  @files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end
  erb(:index, layout: :layout)
end

# View contents of document
get "/new" do
  require_signed_in_user
  erb(:new)
end

# View signin page
get "/users/signin" do 
  erb(:signin)
end

# signin admin and those authorized, return all others to signin.
post "/users/signin" do
  credentials = load_user_credentials
  username = params[:username]

  if credentials.key?(username) && credentials[username] == params[:password]
    session[:username] = username
    session[:message] = "Welcome!"
    redirect "/"
  else
    session[:message] = "Invalid credentials"
    status 422
    erb :signin
  end
end

# signout admin user
post "/users/signout" do
  session.delete(:username)
  session[:message] = "You have been signed out."
  redirect "/"
end

get "/:filename" do 
  file_path = File.join(data_path, params[:filename])

  if File.file?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end

get "/:filename/edit" do
  require_signed_in_user

  file_path = File.join(data_path, params[:filename])
  
  @filename = params[:filename]
  @content = File.read(file_path)
  
  erb(:edit, layout: :layout)
end

post "/create" do
  require_signed_in_user

  filename = params[:filename].to_s
  
  if filename.empty?
    session[:message] = "A name is required."
    status(422)
    erb(:new)
  else
    file_path = File.join(data_path, filename)

    File.write(file_path, "hello")
    session[:message] = "#{params[:filename]} has been created."

    redirect "/"
  end
end

post "/:filename" do
  require_signed_in_user

  file_path = File.join(data_path, params[:filename])

  File.write(file_path, params[:content])
  session[:message] = "File was updated."

  redirect "/"
end

post "/:filename/delete" do 
  require_signed_in_user

  file_path = File.join(data_path, params[:filename])

  File.delete(file_path)

  session[:message] = "#{params[:filename]} has been deleted."
  redirect "/"
end
