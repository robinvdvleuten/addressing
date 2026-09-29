namespace :addressing do
  desc "Report discrepancies in the data files"
  task :verify do
    require_relative "data_verifier"

    discrepancies = Addressing::DataVerifier.new.discrepancies

    if discrepancies.empty?
      puts "No discrepancies found in the data files."
    else
      discrepancies.each { |discrepancy| warn discrepancy }

      abort "\n#{discrepancies.size} #{(discrepancies.size == 1) ? "discrepancy" : "discrepancies"} found. Report upstream, the data files are not edited by hand."
    end
  end
end
