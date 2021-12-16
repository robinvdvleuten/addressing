require "bundler/gem_tasks"
require "rake/testtask"
require "standard/rake"

Dir.glob("tasks/*.rake").each { |r| import r }

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
end

task default: :test
