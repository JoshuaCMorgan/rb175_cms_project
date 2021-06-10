# Setup our test environment
ENV['RACK_ENV'] = "test" #prevents sinatra from starting a web server when testing
require 'fileutils'
require "minitest/autorun"
require "rack/test"
# Include our application
require_relative "../cms.rb"

class CMSTest < Minitest::Test
  include Rack::Test::Methods  # This module gives us methods to work with

  # These methods expect a method called app to exist and return an instance of a Rack application when called.
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

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>Ruby is...</h1>"
  end

  def test_document_not_found
    get "/notafile.ext" # attempt to access nonexistent file
    
    assert_equal(302, last_response.status) # assert that redirection was made by browser
  
    get last_response["Location"] # Request the page that the user was redirected to
   
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "notafile.ext does not exist.")

    get "/" # reload the page

    refute_includes(last_response.body, "notafile.ext does not exit") # refute that body includes error message, assert that our error message has been deleted. 
  end


  def test_editing_document
    create_document("changes.txt")

    get "/changes.txt/edit" # access edit mode

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "<textarea")
    assert_includes(last_response.body, %q(<button type="submit"))
  end 

  def test_updating_document
    post "/changes.txt", content: "This is some text!"

    assert_equal 302, last_response.status

    get last_response["Location"] # Request the page that the user was redirected to
   
    assert_includes(last_response.body, "File was updated.")

    get "/changes.txt" # access the edited page
    
    assert_equal 200, last_response.status
    assert_includes(last_response.body, "This is some text!") # assert that our change to the document has persisted.
  end
end
