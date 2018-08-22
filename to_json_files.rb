ROOT = Dir.pwd
require "#{ROOT}/lib/services/biocode/biocode"
require "#{ROOT}/lib/services/bco_dmo/bco_dmo"

puts "Generating Biocode JSON file: ./biocode/tmp/output.json"
biocode = Biocode.new({})
biocode.download_to_file
puts "Done"
puts ""

puts "Generating BCO-DMO JSON file: ./bco_dmo/tmp/output.json"
bco_dmo = BcoDmo.new({})
bco_dmo.download_to_file
puts "Done"
puts ""
