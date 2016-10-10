#!/usr/bin/env ruby
require 'net/ping'

def up?(host)
    Net::Ping::TCP.service_check = true
    check = Net::Ping::TCP.new(host)
    check.ping?
end

SCHEDULER.every '600s', first_in: 2 do

  elvis = up?('132.187.12.147')

  if elvis == true
    data = '/i3logo.svg'
  else
    data = '/elvis.png'
  end
  
  send_event('elvis', image: "#{data}")
end
