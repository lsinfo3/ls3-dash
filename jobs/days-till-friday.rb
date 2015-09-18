
SCHEDULER.every '2s' do

  date = Time.new
  day = date.strftime("%w")

  to_friday = day.to_i - 5
  if day.to_i == 5
	  send_event('days-till-friday', { title: "Today", text: "is Friday!" })
  else
	  send_event('days-till-friday', { title: to_friday.to_s + " days" })
  end
  
  send_event('days-till-friday', { moreinfo: "Current date: " + date.strftime("%A, %d.%m.%Y") })
end
