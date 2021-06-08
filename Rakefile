
desc 'Run tests'
Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  # glob pattern (**) to match any level in the project directory tree
  t.test_files = FileList['test/**/*_test.rb']
end

