require 'icalendar'
require 'icalendar/recurrence'

require 'net/http'

user = ENV['CHRONOS_USER']
password = ENV['CHRONOS_PASSWORD']
calendar = 'https://chronos.informatik.uni-wuerzburg.de/vacation/home'

def icon_for_event(vacation_event)
  vacation_event.categories.first.downcase
end

def vacation_includes_date?(vacation_event, date)
  regular_event_occurs = (vacation_event.dtstart.to_date..vacation_event.dtend.to_date).include?(date)
  repeated_event_occurs = !vacation_event.occurrences_between(date, date + 1).empty?
  regular_event_occurs || repeated_event_occurs
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
  next_monday = today.next_day(7 - today.wday + 1)
  next_friday = next_monday.next_day(4)
  next_week = (next_monday..next_friday)

  vacations_today = []
  vacations_tomorrow = []
  vacations_next_week = []

  vacations.events.each do |event|
    p event.categories.first.downcase
    vacations_today << { label: event.summary, category: icon_for_event(event)} if vacation_includes_date? event, today
    vacations_tomorrow << { label: event.summary, category: icon_for_event(event) } if vacation_includes_date? event, tomorrow
    vacations_next_week << { label: event.summary, category: icon_for_event(event) } if next_week.any? { |date| vacation_includes_date? event, date }
  end

  vacation_information = {
    today: vacations_today,
    tomorrow: vacations_tomorrow,
    next_week: vacations_next_week
  }

  send_event 'vacations', vacation_information
end
