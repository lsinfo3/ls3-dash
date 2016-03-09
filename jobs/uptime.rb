require 'pry'
require 'time'

SCHEDULER.every '10s', first_in: 0 do

    # get uptime
    uptime = Time.now - IO.read('/proc/uptime').split[0].to_i
    up_str = Time.at(uptime).utc.strftime("%-m months, %-d days, %-H hours")

    # post results
    results = {
      title: uptime,
      text: 'till last AcCident.'
    }

    send_event "uptime", results

end
