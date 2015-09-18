require 'mechanize'
require 'benchmark'
points = []

(1..10).each do |i|
  points << { x: i, y: 0 }
end
last_x = points.last[:x]

url = 'https://raritanos.informatik.uni-wuerzburg.de'
raritan_user = ENV['RARITAN_USER']
raritan_password = ENV['RARITAN_PASSWORD']

m = Mechanize.new { |a| a.ssl_version, a.verify_mode = 'SSLv3', OpenSSL::SSL::VERIFY_NONE}

SCHEDULER.every '5s', first_in: 0 do
  m.get(url) do |page|
    form = page.form_with(:action => '/auth.asp') do |f|
      break if f.nil?
      f.login = raritan_user
      f.password = raritan_password
    end

    page = form.click_button if form

    watt = page.iframes.last.content.search('.dtbl tr:nth-child(2) td:nth-child(6)').text.strip.split(/ /).first.to_f

    last_x += 1
    points << { x: last_x, y: watt }

    send_event('coffee', points: points)
  end
end
