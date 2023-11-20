namespace :addressing do
  task :download do
    # Make sure we're starting from a clean slate.
    raise "The tmp/cldr directory already exists." if Dir.exist?("tmp/cldr")

    # Fetch country data (CLDR).
    puts "Fetching country data."
    system "git clone --depth 1 --branch 42.0.0 https://github.com/unicode-org/cldr-json.git tmp/cldr"
  end
end
