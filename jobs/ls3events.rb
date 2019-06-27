require 'net/http'
require 'set'
require 'icalendar'
require 'icalendar/recurrence'
module Icalendar
  class Value
    def eql?(other_key)
      value == other_key.value
    end
  end
end

user = ENV['CHRONOS_USER']
password = ENV['CHRONOS_PASSWORD']
calendar_a205 = 'https://chronos.informatik.uni-wuerzburg.de/A205/home'
calendar_events = 'https://chronos.informatik.uni-wuerzburg.de/events/home'

def shrink_label(event)
  e = event.summary.to_s
  if event.summary.to_s.length >= 25
    e = event.summary.to_s[0..24]
    e[19..24] = "..." unless e.match(/\s[^\s]+\s*$/)
    e = e.gsub(/\s[^\s]+\s*$/,'...') 
  end
  e
end

def ls3_includes_date?(ls3_event, date)
 ls3_event.dtend = ls3_event.dtstart if ls3_event.dtend.nil? # happens if somebody does not set an end date
 begin
   repeated_event_occurs = !ls3_event.occurrences_between(date, (date + 1.day) - 1.second).empty?
 rescue
   repeated_event_occurs = false
 end
 repeated_event_occurs
end

def get_calendar_events(calendar, user, password)
  uri = URI(calendar)
  req = Net::HTTP::Get.new(calendar)
  req.basic_auth user, password

  params = {
    use_ssl: uri.scheme == 'https',
    verify_mode: OpenSSL::SSL::VERIFY_NONE
  }

  response = Net::HTTP.start(uri.hostname, uri.port, params) do |http|
    http.request(req)
  end

  Icalendar::Calendar.parse(response.body.force_encoding('UTF-8')).first
end



SCHEDULER.every '1h', first_in: 0 do

  today = Date.today
  next_monday = today.next_day(7 - ((today.wday - 1) % 7))
  this_week = (today+1..(next_monday -1))
  next_sunday = next_monday.next_day(6)
  next_week = (next_monday..next_sunday)

  ls3s_today = []
  ls3s_this_week = []
  ls3s_next_week = []

  ls3s = get_calendar_events(calendar_a205, user, password)
  ls3s.events.each do |event|
    ls3s_today << { startdate: event.occurrences_between(today, today+1.day-1.second).first.start_time, label: shrink_label(event), icon: "group", type: event.categories.first, count: event.occurrences_between(today, today+1.day-1.second).first.start_time.in_time_zone('Berlin').strftime("%k:%M") } if ls3_includes_date? event, today
    ls3s_this_week << { startdate: event.occurrences_between(today+1, next_monday-1.second).first.start_time, label: shrink_label(event), icon: "group", type: event.categories.first, count: event.occurrences_between(today+1, next_monday-1.second).first.start_time.in_time_zone('Berlin').strftime("%a, %k:%M") } if this_week.any? { |date| ls3_includes_date? event, date }
    ls3s_next_week << { startdate: event.occurrences_between(next_monday, next_sunday+1.day-1.second).first.start_time, label: shrink_label(event), icon: "group", type: event.categories.first, count: event.occurrences_between(next_monday, next_sunday+1.day-1.second).first.start_time.in_time_zone('Berlin').strftime("%a, %-d.%-m. %H:%M")} if next_week.any? { |date| ls3_includes_date? event, date }
  end

  ls3s = get_calendar_events(calendar_events, user, password)
  ls3s.events.each do |event|
    ls3s_today << { startdate: event.occurrences_between(today, today+1.day-1.second).first.start_time, label: shrink_label(event), icon: "calendar", type: event.categories.first, count: event.occurrences_between(today, today+1.day-1.second).first.start_time.in_time_zone('Berlin').strftime("%k:%M") } if ls3_includes_date? event, today
    ls3s_this_week << { startdate: event.occurrences_between(today+1, next_monday-1.second).first.start_time, label: shrink_label(event), icon: "calendar", type: event.categories.first, count: event.occurrences_between(today+1, next_monday-1.second).first.start_time.in_time_zone('Berlin').strftime("%a, %k:%M") } if this_week.any? { |date| ls3_includes_date? event, date }
    ls3s_next_week << { startdate: event.occurrences_between(next_monday, next_sunday+1.day-1.second).first.start_time, label: shrink_label(event), icon: "calendar", type: event.categories.first, count: event.occurrences_between(next_monday, next_sunday+1.day-1.second).first.start_time.in_time_zone('Berlin').strftime("%a, %-d.%-m. %H:%M")} if next_week.any? { |date| ls3_includes_date? event, date }
  end

 
  ls3_information = [
    { label: 'Today', items: ls3s_today.sort_by { |e| e[:startdate] }.uniq { |e| e[:label] } },
    { label: 'This Week', items: ls3s_this_week.sort_by { |e| e[:startdate] }.uniq { |e| e[:label] } },
    { label: 'Next Week', items: ls3s_next_week.sort_by { |e| e[:startdate] }.uniq { |e| e[:label] } }
  ]

  send_event 'ls3_events', data: ls3_information
end
