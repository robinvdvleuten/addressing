namespace :addressing do
  task :download do
    # Make sure we're starting from a clean slate.
    FileUtils.remove_dir("tmp/cldr", true) if Dir.exist?("tmp/cldr")
    FileUtils.remove_dir("tmp/addressing", true) if Dir.exist?("tmp/addressing")

    # Fetch country data (CLDR).
    puts "Fetching country data."
    system "git clone --depth 1 --branch 42.0.0 https://github.com/unicode-org/cldr-json.git tmp/cldr"

    # Fetch commerceguys/addressing repo.
    puts "Fetching commerceguys/addressing repository."
    system "git clone --depth 1 --branch v1.4.2 https://github.com/commerceguys/addressing.git tmp/addressing"
  end
end
