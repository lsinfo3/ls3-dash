require 'pry'
require 'mysql2'

db_url = ENV['EMSV_DB_URL']
user = ENV['EMSV_DB_USER']
pass = ENV['EMSV_DB_PASS']

SCHEDULER.every '5m', first_in: 0 do
  db = Mysql2::Client.new(host: db_url, username: user, password: pass,
                          port: 3306, database: 'em16')

  # Top 10
  sql = 'SELECT *  FROM users ORDER BY punkte DESC, ' \
    'exakt DESC, trend DESC LIMIT 10;'
  results = db.query(sql)
  top10 = results.map do |row|
    { label: row['name'], count: row['punkte'] }
  end

  # Ranking exakt
  sql = 'SELECT * FROM users ORDER BY exakt DESC, punkte DESC LIMIT 10;'
  results = db.query(sql)
  numbers = (1..5).to_a.map { |i| { label: i } }
  exakt = results.map do |row|
    { mid: row['name'], count: row['exakt'] }
  end
  exakt = numbers.zip(exakt).map { |a,b| a.merge(b)}

  # Trend
  sql = 'SELECT * FROM users ORDER BY trend DESC, punkte DESC LIMIT 10;'
  results = db.query(sql)
  numbers = (1..5).to_a.map { |i| { label: i } }
  trend = results.map do |row|
    { mid: row['name'], count: row['trend'] }
  end
  trend = numbers.zip(trend).map { |a,b| a.merge(b)}

  # Games past
  sql = 'SELECT * FROM games WHERE ' \
    'CAST(CONCAT(date,\' \',time) AS DATETIME) < (NOW()) ' \
    'AND date >= CURDATE()-2 ORDER BY date, number;'
  results = db.query(sql)
  matches_past = results.map do |row|
    label = row['date'].to_s + ' ' + row['time'].to_s[11..15]
    mid = row['team1'] + ' - ' + row['team2']
    result = row['goals1'].to_s + ':' + row['goals2'].to_s
    { label: label, mid: mid, count: result }
  end

  # Upcoming games
  sql = 'SELECT * FROM games WHERE ' \
    'CAST(CONCAT(date,\' \',time) AS DATETIME) >= (NOW()) ' \
    'AND date <= CURDATE()+2 ORDER BY date, number;'
  results = db.query(sql)
  matches_upcoming = results.map do |row|
    label = row['date'].to_s + ' ' + row['time'].to_s[11..15]
    mid = row['team1'] + ' - ' + row['team2']
    { label: label, mid: mid, count: '' }
  end

  # update dashboard
  send_event 'ranking-top10', data: [
    { label: 'Top 10', items: top10[0, 5] },
    { label: '', items: top10[5, 5] }]
  send_event 'ranking-exakt', data: [
    { label: 'Exact Results', items: exakt[0, 5] },
    { label: '', items: exakt[5, 5] }]
  send_event 'ranking-trend', data: [
    { label: 'Trend', items: trend[0, 5] },
    { label: '', items: trend[5, 5] }]
  send_event 'games', data: [
    { label: 'Past and Running Matches', items: matches_past },
    { label: 'Upcoming Matches', items: matches_upcoming }]
end
