require 'pry'
require 'mysql2'

db_url = ENV['EMSV_DB_URL']
user = ENV['EMSV_DB_USER']
pass = ENV['EMSV_DB_PASS']


SCHEDULER.every '5m', first_in: 0 do

  # Myql connection
  db = Mysql2::Client.new(:host => db_url, :username => user, :password => pass, :port => 3306, :database => "em16" )

  # Mysql query
  sql = "SELECT * FROM users ORDER BY punkte DESC, exakt DESC, trend DESC LIMIT 10;"
  results = db.query(sql)
  top10 = results.map do |row|
    row = {
      :label => row['name'],
      :count => row['punkte']
    }
  end
  p top10

  # Mysql query
  sql = "SELECT * FROM users ORDER BY exakt DESC, punkte DESC LIMIT 10;"
  results = db.query(sql)
  exakt = results.map do |row|
    row = {
      :label => row['name'],
      :count => row['exakt']
    }
  end

  # Mysql query
  sql = "SELECT * FROM users ORDER BY trend DESC, punkte DESC LIMIT 10;"
  results = db.query(sql)
  trend = results.map do |row|
    row = {
      :label => row['name'],
      :count => row['trend']
    }
  end




  send_event 'ranking-top10', data: [{ label: 'Top 10', items: top10 }]
  send_event 'ranking-exakt', data: [{ label: 'Exact Results', items: exakt }]
  send_event 'ranking-trend', data: [{ label: 'Trend', items: trend }]
  puts 'new run'
end
