require 'mechanize'
require 'benchmark'
require 'rest_client'
require 'json'

# settings
url = 'https://raritanos.informatik.uni-wuerzburg.de'
raritan_user = ENV['RARITAN_USER']
raritan_password = ENV['RARITAN_PASSWORD']

cooking_threshold = 500
coffee_start_text = 'Ein lieber Mitarbeiter macht Kaffee...'
coffee_brewing_finished_text = 'Kaffee fertig!'

# init plot
points = []
(1..120).each do |i|
  points << { x: i, y: 0 }
end
last_x = points.last[:x]

# init internal variables
last_coffee_start = DateTime.now
last_coffee_finished = DateTime.now  # for the announcement in the coffee widget
is_cooking = false
avg_brewing_duration = nil 

# send default value to dashboard
send_event('coffee-text', { value: 100 }) # init

# query page
m = Mechanize.new { |a| a.ssl_version, a.verify_mode = 'SSLv3', OpenSSL::SSL::VERIFY_NONE }
SCHEDULER.every '15s', first_in: 0 do
  m.get(url) do |page|
    # get watt value from power plug
    form = page.form_with(:action => '/auth.asp') do |f|
      break if f.nil?
      f.login = raritan_user
      f.password = raritan_password
    end
    page = form.click_button if form
    watt = page.iframes.last.content.search('.dtbl tr:nth-child(2) td:nth-child(6)').text.strip.split(/ /).first.to_f

    # is cooking?
    previous_is_cooking = is_cooking
    is_cooking = watt > cooking_threshold ? true : false

    # parse possible events (brewing started/finished)
    last_coffee_finished = DateTime.now if previous_is_cooking && !is_cooking
    last_coffee_start = DateTime.now if is_cooking && !previous_is_cooking
    
    # send updates to board
    send_event('coffee', { points: points, coffee_status: is_cooking ? 'filling' : 'unknown', elast_coffee: last_coffee_finished.to_s });
    send_event('coffee-text', { value: 0, text: coffee_brewing_finished_text }) if previous_is_cooking && !is_cooking

    # update plot
    last_x += 1
    points.shift
    points.push({ x: last_x, y: watt })
  end
end

def get_avg_brewing_duration
  elastic_url = 'http://132.187.12.139:9200/logstash-*/_search'
  q = '{ "query": { "filtered": { "query": {"query_string": { "analyze_wildcard": true, "query": "_type:\"coffee log file\" AND log_event:\"Kaffee fertig!\" -time_left:[* TO 200]" } } } },"size": 0, "aggs": { "1": { "avg": { "field": "time_left" } } } }'
  begin
  	r = JSON.parse RestClient.get(elastic_url, params: { source: q })
	r['aggregations']['1']['value']
  rescue Errno::ECONNREFUSED, Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError, RestClient::RequestTimeout
 	443
  end	
end

def str_pad_left(string, pad, length)
  (Array.new(length+1).join(pad.to_s) << string.round(0).to_s).slice(-length,length)
end

SCHEDULER.every '1h', first_in: 0 do
  avg_brewing_duration = get_avg_brewing_duration
end

SCHEDULER.every '1s' do
  if is_cooking && avg_brewing_duration
    time_left = avg_brewing_duration - ((DateTime.now.to_i - last_coffee_start.to_i).to_f)
    min = (time_left / 60).floor
    sec = time_left - min * 60 
    send_event('coffee-text', { value: "#{str_pad_left(min,"0",2)}:#{str_pad_left(sec,"0",2)}", text: coffee_start_text, max: avg_brewing_duration, min: 0 }) unless time_left < 0
    p "#{str_pad_left(min,"0",2)}:#{str_pad_left(sec,"0",2)}"
  end
end
