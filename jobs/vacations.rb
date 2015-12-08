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
calendar = 'https://chronos.informatik.uni-wuerzburg.de/vacation/home'

def icon_for_event(vacation_event)
  icons = {
    'urlaub' => 'glass',
    'dienstreise' => 'laptop'
  }
  icons.fetch((vacation_event.categories.first || '').downcase, 'question')
end

def vacation_includes_date?(vacation_event, date)
  regular_event_occurs = (vacation_event.dtstart.to_date...vacation_event.dtend.to_date).include?(date)
  repeated_event_occurs = !vacation_event.occurrences_between(date, (date.to_time + 1.day - 1.second).to_datetime).empty?
  regular_event_occurs || repeated_event_occurs
end

def days_of_vacation_next_week_for(vacation_events, name, type, start_week, end_week)
  vacation_events.select do |e|
    e.summary.to_s == name
  end.select do |e|
    !(start_week > e.dtend.to_date || end_week < e.dtstart.to_date) && (e.categories.first== type)
  end.map do |e|
    s = Date::DAYNAMES[[start_week, e.dtstart.to_date].max.wday][0..2]
    e = Date::DAYNAMES[[end_week, (e.dtend.to_date.to_time - 1.second).to_date].min.wday][0..2]
    r = ", #{s}-#{e}" if s != e
    r = ", #{s}" if s==e
    r
  end.join
#  vacation_events.select do |e|
#    e.summary.to_s == name
#  end.select do |e|
#    !(start_week > e.dtend.to_date || end_week < e.dtstart.to_date) && (e.categories.first== type)
#  end.map do |e|
#    ([end_week, (e.dtend.to_date.to_time - 1.second).to_date].min - [start_week, e.dtstart.to_date].max).to_i + 1
#  end.sum
end

SCHEDULER.every '1h', first_in: 0 do
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

  vacations = Icalendar.parse(response.body).first

  today = Date.today
  tomorrow = today + 1
  next_monday = today.next_day(7 - ((today.wday - 1) % 7))
  next_friday = next_monday.next_day(4)
  next_week = (next_monday..next_friday)

  vacations_today = []
  vacations_tomorrow = []
  vacations_next_week = []

  vacations.events.each do |event|
    vacations_today << { label: event.summary.to_s, icon: icon_for_event(event), type: event.categories.first } if vacation_includes_date? event, today
    vacations_tomorrow << { label: event.summary.to_s, icon: icon_for_event(event), type: event.categories.first } if vacation_includes_date? event, tomorrow
    vacations_next_week << { label: event.summary.to_s, icon: icon_for_event(event), type: event.categories.first } if next_week.any? { |date| vacation_includes_date? event, date }
  end

  vacations_next_week.each do |entry|
    entry[:count] = days_of_vacation_next_week_for(vacations.events, entry[:label], entry[:type], next_monday, next_friday)[2..-1]
  end

  vacation_information = [
    { label: 'Today', items: vacations_today.sort_by { |e| e[:label] }.uniq },
    { label: 'Tomorrow', items: vacations_tomorrow.sort_by { |e| e[:label] }.uniq },
    { label: 'Next Week', items: vacations_next_week.sort_by { |e| e[:label] }.uniq }
  ]

  send_event 'vacations', data: vacation_information
end
