require "sinatra"
require "sinatra/reloader"
require "redcarpet"
require "yaml"
require "bcrypt"


configure do
  enable :sessions  #Enable sessions in the application so we can persist data between requests. 
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

def load_file_content(path) # return nil if not proper extention(helps with security)
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

def username_invalid?(username)
  credentials = load_user_credentials

  if credentials.key?(username)
    "Username already exists."
  elsif username.size < 3
    "Username is too short, needs to be at least 3 letters."
  end
end

def password_invalid?(pw)
  "Password needs to be at least 8 characters long." if  pw.size < 8
end

def valid_credentials?(username, password)
  credentials = load_user_credentials

  # give current user an already generated encrypted password
  if credentials.key?(username)
    bcrypt_password = BCrypt::Password.new(credentials[username])
     bcrypt_password == password# check if encrypted password and users's password same
  else
    false
  end
end

def add_user_to_configuration(users)
  file_path = File.join(configuration_path, "users.yml")
  test_file_path = File.join(configuration_path, "test/users.yml")
  File.write(file_path, users.to_yaml)
  File.write(test_file_path, users.to_yaml)
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

  if valid_credentials?(username, params[:password])
    session[:username] = username
    session[:message] = "Welcome!"
    redirect "/"
  else
    session[:message] = "Invalid credentials"
    status 422  # Unprocessable Entity
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

get "/users/signup" do
  erb(:signup)
end


post "/users/create_user" do 
  username = params[:username]
  password = params[:password]

  error = username_invalid?(username) || password_invalid?(password)

  if error
    session[:message] = error
    status 422
    erb :signup
  else 
    credentials = load_user_credentials
    hash_password = BCrypt::Password.create(password)
    credentials[username] = hash_password.to_s

    add_user_to_configuration(credentials)

    session[:message] = "You have signed up successfully. You may now sign in."
    session[:user] = username
    redirect "/"
  end
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
