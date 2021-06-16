require "rake/testtask"

# from command-line run: bundle exec rake test
# this code will run the tests
desc 'Run tests'
task :test
Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  # glob pattern (**) to match any level in the project directory tree
  t.test_files = FileList['test/**/*_test.rb']
end

