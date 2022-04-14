namespace :addressing do
  task :download do
    require "fileutils"

    service_url = "https://chromium-i18n.appspot.com/ssl-address"

    # Make sure we're starting from a clean slate.
    raise "The tmp/cldr directory already exists." if Dir.exist?("tmp/cldr")
    raise "The tmp/google directory already exists." if Dir.exist?("tmp/google")

    # Make sure aria2 is installed.
    aria_version = `aria2c --version`
    raise "aria2 must be installed." if aria_version.empty? || aria_version.index("aria2 version").nil?

    # Prepare the filesystem.
    FileUtils.mkdir_p "tmp/google"

    # Fetch country data (CLDR).
    puts "Fetching country data."
    system "git clone --depth 1 --branch 41.0.0 https://github.com/unicode-org/cldr-json.git tmp/cldr"

    # Fetch address data (Google).
    puts "Generating the url list.\n"
    File.write "tmp/url_list.txt", generate_url_list(service_url)

    # Invoke aria2 and fetch the data.
    puts "Downloading the raw data from Google's endpoint."
    system "aria2c -u 16 -i tmp/url_list.txt -d tmp/google"

    puts "Download complete."
  end
end

def generate_url_list(service_url)
  require "open-uri"

  index = URI.open(service_url).read

  # Get all links that start with /ssl-address/data.
  # This avoids the /address/examples urls which aren't needed.
  list = index.scan(/<a\shref='\/ssl-address\/data\/([^']*)'>/im).map do |href|
    # Replace the url encoded single slash with a real one.
    href = href.first.gsub("&#39;", "'")
    # Convert 'US/CA' into 'US_CA.json'.
    filename = href.tr("/", "_") + ".json"
    url = "#{service_url}/data/#{href}"
    # aria2 expects the out= parameter to be in the next row, indented by two spaces.
    url += "\n  out=#{filename}"
    url
  end

  list.join("\n")
end
