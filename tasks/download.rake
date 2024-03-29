namespace :addressing do
  task :download do
    # Make sure we're starting from a clean slate.
    FileUtils.remove_dir("tmp/addressing", true)

    # Fetch commerceguys/addressing repo.
    puts "Fetching commerceguys/addressing repository."
    system "git clone --depth 1 --branch v2.2.0 https://github.com/commerceguys/addressing.git tmp/addressing"
  end
end
