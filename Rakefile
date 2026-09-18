require "bundler/gem_tasks"
require "rake/testtask"
require "standard/rake"

Dir.glob("tasks/*.rake").each { |r| import r }

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
end

# The marshalled address formats are a build artifact, not a source file:
# regenerate them before running tests or packaging the gem.
task build: "addressing:dump"
task test: "addressing:dump"

task default: :test
