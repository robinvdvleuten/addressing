namespace :addressing do
  task dump: :generate do
    require "json"

    root_dir = File.expand_path("../..", __FILE__)
    definitions = {}

    # Read from JSON.
    File.readlines("#{root_dir}/data/address_formats.json").each do |line|
      definition = JSON.parse(line, symbolize_names: true)
      definitions[definition[:country_code]] = definition
    end

    # Save to file.
    File.open("#{root_dir}/data/address_formats.dump", "w") do |f|
      Marshal.dump definitions, f
    end
  end
end
