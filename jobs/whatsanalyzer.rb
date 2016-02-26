require 'mechanize'
require 'benchmark'
require 'rest_client'
require 'json'

# settings
url = 'http://whatsanalyzer.informatik.uni-wuerzburg.de/admin/dashboard.jsp'

# query page
m = Mechanize.new { |a| a.ssl_version, a.verify_mode = 'SSLv3', OpenSSL::SSL::VERIFY_NONE }
m.add_auth(url, 'michi', '')
SCHEDULER.every '1m', first_in: 0 do
  m.get(url) do |page|
    # get current chats
    # puts page.at('head').text
    num_chats = page.at('head').text.match(/numOfChatsToday = ([0-9]+);/i).captures
    #puts num_chats

    # send updates to board
    send_event('whatsanalyzer', { current: num_chats, last: 0 })
  end
end

