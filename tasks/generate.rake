namespace :addressing do
  desc "Download commerceguys/addressing, at the pinned version or the given tag"
  task :download, [:version] do |_task, args|
    require_relative "data_sync"

    puts "Fetching commerceguys/addressing repository."
    Addressing::DataSync.new(version: args[:version] || Addressing::DataSync::UPSTREAM_VERSION).download
  end

  desc "Sync the data files with commerceguys/addressing, at the pinned version or the given tag"
  task :generate, [:version] => :download do |_task, args|
    require_relative "data_sync"

    puts "Syncing the data files."
    Addressing::DataSync.new(version: args[:version] || Addressing::DataSync::UPSTREAM_VERSION).sync

    puts "Done."

    # Upstream maintains its data by hand, report what does not add up.
    Rake::Task["addressing:verify"].invoke
  end
end
