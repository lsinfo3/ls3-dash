SCHEDULER.every '1200s', first_in: 2 do
  date = Time.new
  day = date.strftime '%w' # (Sunday is 0, 0..6)

  if day.to_i == 4
    data = { title: 'Tomorrow', text: 'is Friday!' }
  elsif day.to_i == 5
    data = { title: 'Thank god', text: "it's Friday!" }
  elsif (day.to_i == 6) || (day.to_i == 0)
    data = { title: 'Today', text: 'is the weekend!' }
  else
    to_friday = 5 - day.to_i
    data = { title:  "#{to_friday} days", text: 'till Friday.' }
  end

  #  data.merge! moreinfo: "Current date: %s" % date.strftime("%A, %d.%m.%Y")
  send_event 'days-till-friday', data
end
