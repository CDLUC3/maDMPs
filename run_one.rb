ROOT = Dir.pwd
require "#{ROOT}/geome/geome"
app = Geome.new
app.download_to_file
