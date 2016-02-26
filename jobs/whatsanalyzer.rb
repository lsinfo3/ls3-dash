require 'mechanize'
require 'benchmark'
require 'rest_client'
require 'json'

# settings
url = 'http://whatsanalyzer.informatik.uni-wuerzburg.de/admin/dashboard'

# query page
m = Mechanize.new { |a| a.ssl_version, a.verify_mode = 'SSLv3', OpenSSL::SSL::VERIFY_NONE }
SCHEDULER.every '15s', first_in: 0 do
  m.get(url) do |page|
    # get current chats
    num_chats = page.content.search('.chatsTodayDiv').text.to_f

    # send updates to board
    send_event('dota-Valentin', { current: num_chats, last: 0 })
  end
end

