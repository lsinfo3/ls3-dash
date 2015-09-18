require 'mechanize'
require 'benchmark'

cooking_threshold = 500

points = []

(1..120).each do |i|
  points << { x: i, y: 0 }
end
last_x = points.last[:x]

url = 'https://raritanos.informatik.uni-wuerzburg.de'
raritan_user = ENV['RARITAN_USER']
raritan_password = ENV['RARITAN_PASSWORD']

m = Mechanize.new { |a| a.ssl_version, a.verify_mode = 'SSLv3', OpenSSL::SSL::VERIFY_NONE}

last_coffee = DateTime.now
is_cooking = false

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
    is_cooking = watt > cooking_threshold ? 'filling' : 'unknown'
    last_coffee =  DateTime.now if previous_is_cooking && !is_cooking

    data = { points: points, coffee_status: is_cooking, last_coffee: last_coffee.to_s }
    p data
    send_event('coffee', data)
  end
end
