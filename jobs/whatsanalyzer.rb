require 'mechanize'
require 'benchmark'
require 'rest_client'
require 'json'
require 'date'

# settings
url = 'https://whatsanalyzer.informatik.uni-wuerzburg.de/admin/dashboard.jsp'
old_value = [0, 0, 0, 0, 0, 0, 0]

# query page
m = Mechanize.new { OpenSSL::SSL::VERIFY_NONE }
m.add_auth(url, 'michi', '')
SCHEDULER.every '30m', first_in: 0 do
  m.get(url) do |page|
    # get current chats
    # puts page.at('head').text
    #num_chats = page.at('head').text.match(/numOfChatsToday = ([0-9]+);/i).captures
    num_chats = page.at('body').text.match(/Insgesamt gesammelte Chats: ([0-9]+)/i).captures
    #puts num_chats
    old_value[DateTime.now.wday] = num_chats

    # send updates to board
    old = old_value[(DateTime.now.wday - 1) % 7]
    send_event('whatsanalyzer', { current: num_chats, last: old })
  end
end

