ROOT = Dir.pwd
#require "#{ROOT}/geome/geome"
#app = Geome.new
require "#{ROOT}/bco_dmo/bco_dmo"
app = BcoDmo.new
app.download_to_file
