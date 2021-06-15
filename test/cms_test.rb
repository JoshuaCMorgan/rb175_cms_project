# Setup our test environment
ENV['RACK_ENV'] = "test" #prevents sinatra from starting a web server when testing

require 'fileutils'
require "minitest/autorun"
require "rack/test"
# Include our application
require_relative "../cms.rb"

class CMSTest < Minitest::Test
  include Rack::Test::Methods  # This module gives us methods to work with

  # These methods expect a method called app to exist and will return an instance of a Rack application when called.
  def app
    Sinatra::Application
  end

  def setup # create the data directory if it doesn't exist 
    FileUtils.mkdir_p(data_path)
  end

  def teardown # remove the data directory it it exists
    FileUtils.rm_rf(data_path)
  end

  # creates empty files by default, but an optional second parameter allows the contents of the file to be passed in
  def create_document(name, content = "")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
  end

  ## get at the session object and its values
  def session
    last_request.env["rack.session"]
  end

  def admin_session
    # By passing a value for the session, we can skip right to testing
  # functionality that requires being signed in. The second argument is
  # an empty hash because we aren't passing any params to the request.
    { "rack.session" => { username: "admin" } }
  end 
  
  #validates the response has a successful response 
  #validates the response contains the names of two documents.
  def test_index
    create_document("about.md")     # setup necessary data
    create_document("changes.txt")

    get "/"
    
    assert_equal(200, last_response.status)
    assert_equal("text/html;charset=utf-8", last_response["Content-Type"])
    assert_includes(last_response.body, "about.md")
    assert_includes(last_response.body, "changes.txt")

  end
  
  # validates the response has a successful response
  # validates the response contains some text from a document.
  def test_viewing_text_document
    create_document("history.txt", content = "2018 - Ruby 2.6 released.")

    get "/history.txt"
    
    assert_equal(200, last_response.status)
    assert_equal("text/plain", last_response["Content-Type"])
    assert_includes(last_response.body, "2018 - Ruby 2.6 released.")
  end

  def test_viewing_markdown_document
    create_document("about.md", content = "# Ruby is...")

    get "/about.md"

    assert_equal(200, last_response.status)
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>Ruby is...</h1>"
  end

  def test_document_not_found
    get "/notafile.ext" # attempt to access nonexistent file
    
    assert_equal(302, last_response.status) # assert that redirection was made by browser
    assert_equal("notafile.ext does not exist.", last_request.env["rack.session"][:message])
  end


  def test_editing_document # verify admin access edit mode
    create_document("changes.txt")

    get "/changes.txt/edit", {}, admin_session 

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "<textarea")
    assert_includes(last_response.body, %q(<button type="submit"))
  end 


  def test_editing_document_by_admin_only
    create_document("changes.txt")
    # Submit the sign in form &
    # Verify that the user is signed in by testing something that required being signed in
    get "changes.txt/edit", {}, admin_session
    
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "Edit content of")
    assert_includes(last_response.body, %q(<button type="submit">))
  end

  def test_editing_document_signed_out
    create_document("changes.txt")

    get "changes.txt/edit"

    assert_equal(302, last_response.status)
    assert_equal("You must be signed in to do that.", session[:message])
  end

  def test_updating_document_occurred
    post "/changes.txt", {content: "This is some text!"}, admin_session
    
    assert_equal(302, last_response.status)
    assert_equal("File was updated.", session[:message])

    get "/changes.txt" # access the edited page
    
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "This is some text!") # assert that our change to the document has persisted.
  end

  def test_view_new_document_form
    get "/new", {}, admin_session

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "<input")
    assert_includes(last_response.body, %q(<button type="submit"))
  end

  def test_view_new_document_signed_out
    get "/new"

    assert_equal(302, last_response.status)
    assert_equal("You must be signed in to do that.", session[:message])
  end

  
  def test_create_new_document_without_filename
    post "/create", {filename: ""}, admin_session

    assert_equal(422, last_response.status)
    assert_includes(last_response.body, "A name is required")
  end
  
  def test_create_new_document
    post "/create", {filename: "test.txt"}, admin_session
   
    assert_equal(302, last_response.status)
    assert_equal("test.txt has been created.", session[:message])

    get "/"
    assert_includes(last_response.body, "test.txt")
  end

  def test_create_new_document_signed_out
    post "/create", {filename: "test.txt"}

    assert_equal(302, last_response.status)
    assert_equal("You must be signed in to do that.", session[:message])
  end

  def test_deleted_file
    create_document("test.txt")
    post "/test.txt/delete", {}, admin_session
    
    assert_equal(302, last_response.status)
    assert_equal("test.txt has been deleted.", session[:message])
  
     get "/"
     
    refute_includes(last_response.body, %q(<a href="/test.txt"</a>))
  end

  def test_signin_form
    get "/users/signin"
    
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "<input")
    assert_includes(last_response.body, %q(<button type="submit"))
  end

  def test_signin_proper
    post "/users/signin", username: "admin", password: "secret"

    assert_equal(302, last_response.status)
    assert_equal("Welcome!", session[:message])
    assert_equal("admin", session[:username])

    get last_response["Location"]
   
    assert_includes(last_response.body, "Signed in as admin")
  end

  def test_sigin_with_bad_credentials
    post "/users/signin", username: "invalid", password: "abcd"

    assert_equal(422, last_response.status)
    assert_nil(last_request.env["rack.session"][:username])
    assert_includes(last_response.body, "Invalid credentials")
  end

  def test_signout
    get "/", {}, {"rack.session" => { username: "admin" } }
    assert_includes last_response.body, "Signed in as admin"
    
    post "/users/signout"
    assert_equal "You have been signed out.", session[:message]
    
    get last_response["Location"]
    assert_nil session[:username]
    assert_includes last_response.body, "Sign In"
  end

  def test_signout_non_admin
    get "/", {}, {"rack.session" => { username: "josh" } }
    assert_includes last_response.body, "Signed in as josh"
    
    post "/users/signout"
    assert_equal "You have been signed out.", session[:message]
    
    get last_response["Location"]
    assert_nil session[:username]
    assert_includes last_response.body, "Sign In"
  end
end

# def test_signout
#   post "/users/signin", username: "admin", password: "secret"
#   assert_equal("Welcome!", session[:message])

#   post "/users/signout", username: "admin", password: "secret"
#   assert_equal(302, last_response.status)
#   assert_equal("You have been signed out.", session[:message])
  
#   get last_response["Location"]
#   assert_includes(last_response.body, "Sign In")
#   refute_includes(last_response.body, "Signed in as admin")
# end



