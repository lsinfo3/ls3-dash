require 'pry'
require 'time'

SCHEDULER.every '10s', first_in: 0 do

    # get uptime
    uptime = IO.read('/proc/uptime').split[0].to_i
    days = uptime / (60 * 60 * 24)
    hours = (uptime / (60 * 60)) % 24
    minutes = (uptime / 60) % 60
    up_str = format("%d days, %d hours, %d mins", days, hours, minutes)

    # post results
    results = {
      title: up_str,
      text: 'since the last server crash nightmare.'
    }

    send_event "uptime", results

end
