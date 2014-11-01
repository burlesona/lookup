require 'pg'
require 'active_record'
require 'geocoder'

DATABASE_URL = "postgres://Andrew@localhost/tests"
ActiveRecord::Base.establish_connection(DATABASE_URL)

begin
  ActiveRecord::Base.connection.execute "CREATE TABLE neighborhoods (id serial PRIMARY KEY, name varchar(50) NOT NULL, poly polygon NOT NULL);"
rescue
  puts "DB is Bootstrapped"
end

require_relative './neighborhood'
