require 'icalendar'
require 'net/http'

user = ENV['CHRONOS_USER']
password = ENV['CHRONOS_PASSWORD']
calendar = 'https://chronos.informatik.uni-wuerzburg.de/vacation/home'

SCHEDULER.every '1h', first_in: 0 do
  uri = URI(calendar)
  req = Net::HTTP::Get.new(calendar)
  req.basic_auth user, password

  response = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https',
  :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
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
    vacation_date = event.dtstart.to_date
    if vacation_date == { label: today }
      vacations_today << event.summary
    elsif vacation_date == tomorrow
      vacations_tomorrow << { label: event.summary }
    elsif next_week.include? vacation_date
      vacations_next_week << { label: event.summary }
    end
  end

  vacation_information = {
    today: vacations_today,
    tomorrow: vacations_tomorrow,
    next_week: vacations_next_week
  }

  send_event 'vacations', vacation_information
end
