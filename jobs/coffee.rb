require 'mechanize'
require 'benchmark'
require 'rest_client'
require 'json'

cooking_threshold = 500

points = []

(1..120).each do |i|
  points << { x: i, y: 0 }
end
last_x = points.last[:x]

url = 'https://raritanos.informatik.uni-wuerzburg.de'
raritan_user = ENV['RARITAN_USER']
raritan_password = ENV['RARITAN_PASSWORD']

m = Mechanize.new { |a| a.ssl_version, a.verify_mode = 'SSLv3', OpenSSL::SSL::VERIFY_NONE }

last_coffee = DateTime.now
last_coffee_start = DateTime.now
is_cooking = false
avg_brewing_duration = 0

coffee_start_text = 'Ein lieber Mitarbeiter macht Kaffee...'
coffee_brewing_finished_text = 'Kaffee fertig!'
send_event('coffee-text', { value: 0 })

SCHEDULER.every '15s', first_in: 0 do
  m.get(url) do |page|
    form = page.form_with(:action => '/auth.asp') do |f|
      break if f.nil?
      f.login = raritan_user
      f.password = raritan_password
    end

    page = form.click_button if form

    watt = page.iframes.last.content.search('.dtbl tr:nth-child(2) td:nth-child(6)').text.strip.split(/ /).first.to_f

    last_x += 1
    points.shift
    points.push({ x: last_x, y: watt })

    previous_is_cooking = is_cooking
    is_cooking = watt > cooking_threshold ? true : false
    last_coffee = DateTime.now if previous_is_cooking && !is_cooking
    last_coffee_start = DateTime.now if is_cooking && !previous_is_cooking
    send_event('coffee-text', { value: 100, text: coffee_brewing_finished_text }) if previous_is_cooking && !is_cooking

    data = { points: points, coffee_status: is_cooking ? 'filling' : 'unknown', elast_coffee: last_coffee.to_s }
    send_event('coffee', data)
  end
end

def get_avg_brewing_duration
  elastic_url = 'http://132.187.12.139:9200/logstash-*/_search'
  q = '{ "query": { "filtered": { "query": {"query_string": { "analyze_wildcard": true, "query": "_type:\"coffee log file\" AND log_event:\"Kaffee fertig!\" -elapsed_time:[* TO 200]" } } } },"size": 0, "aggs": { "1": { "avg": { "field": "elapsed_time" } } } }'
  begin
  	r = JSON.parse RestClient.get(elastic_url, params: { source: q })
	r['aggregations']['1']['value']
  rescue Errno::ECONNREFUSED
 	443
  end	
end

SCHEDULER.every '1h', first_in: 0 do
  avg_brewing_duration = get_avg_brewing_duration
end

SCHEDULER.every '1s', first_in: 0 do
  send_event('coffee-text', { value: ((DateTime.now.to_i - last_coffee_start.to_i).to_f / avg_brewing_duration * 100).round(1), text: coffee_start_text }) if is_cooking
end
