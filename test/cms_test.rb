# Setup our test environment
ENV['RACK_ENV'] = "test" #prevents sinatra from starting a web server when testing
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

  #validates the response has a successful response 
  #validates the response contains the names of the three documents.
  def test_index
    get "/"
    
    assert_equal(200, last_response.status)
    assert_equal("text/html;charset=utf-8", last_response["Content-Type"])
    assert_includes(last_response.body, "about.md")
    assert_includes(last_response.body, "changes.txt")
    assert_includes(last_response.body, "history.txt")
  end
  
  # validates the response has a successful response
  # validates the response contains some text from a document.
  def test_viewing_text_document
    get "/history.txt"
    
    assert_equal(200, last_response.status)
    assert_equal("text/plain", last_response["Content-Type"])
    assert_includes(last_response.body, "2018 - Ruby 2.6 released.")
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
    get "/changes.txt/edit" # access edit mode

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "<textarea")
    assert_includes(last_response.body, %q(<button type="submit"))
  end 

  def test_updating_document
    post "/changes.txt", content: "This is some text!"

    assert_equal 302, last_response.status

    get last_response["Location"] # Request the page that the user was redirected to
   
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "File was updated.")

    get "/changes.txt" # access the edited page

    assert_includes(last_response.body, "This is some text!") # assert that our change to the document has persisted.

  end
end
