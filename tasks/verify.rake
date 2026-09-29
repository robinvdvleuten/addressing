namespace :addressing do
  desc "Report discrepancies in the data files"
  task :verify do
    require_relative "data_verifier"

    result = Addressing::DataVerifier.new.verify(known: Addressing::DataVerifier.known_discrepancies)

    result.known.each { |discrepancy| puts "Known, waits for upstream: #{discrepancy}" }

    if result.ok?
      puts "No unexpected discrepancies found in the data files."
      next
    end

    result.unexpected.each { |discrepancy| warn "Unexpected: #{discrepancy}" }
    result.resolved.each { |discrepancy| warn "Resolved: #{discrepancy}" }

    messages = []
    messages << "Report an unexpected discrepancy upstream and add it to tasks/known_discrepancies.yml, the data files are not edited by hand." if result.unexpected.any?
    messages << "Remove a resolved discrepancy from tasks/known_discrepancies.yml." if result.resolved.any?

    abort "\n#{messages.join("\n")}"
  end
end
