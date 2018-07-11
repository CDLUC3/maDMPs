require 'mysql2'
require 'active_record'

ActiveRecord::Base.establish_connection(
  adapter: 'mysql2',
  database: 'maDMPs',
  username: 'root'
)
