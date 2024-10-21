require_relative "lib/addressing/version"

Gem::Specification.new do |spec|
  spec.name = "addressing"
  spec.version = Addressing::VERSION
  spec.summary = "Addressing library powered by CLDR and Google's address data"
  spec.homepage = "https://github.com/robinvdvleuten/addressing"
  spec.license = "MIT"

  spec.author = "Robin van der Vleuten"
  spec.email = "robinvdvleuten@gmail.com"

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/robinvdvleuten/addressing/issues",
    "changelog_uri" => "https://github.com/robinvdvleuten/addressing/blob/main/CHANGELOG.md"
  }

  spec.files = Dir["{data,lib}/**/*"] + %w[README.md LICENSE CHANGELOG.md]
  spec.require_path = "lib"

  spec.required_ruby_version = ">= 3.1"
end
