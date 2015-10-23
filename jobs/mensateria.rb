require 'nokogiri'
require 'open-uri'
require 'date'

url = 'http://www.studentenwerk-wuerzburg.de/wuerzburg/essen-trinken/speiseplaene.html?tx_thmensamenu_pi2%5Bmensen%5D=54&tx_thmensamenu_pi2%5Baction%5D=show&tx_thmensamenu_pi2%5Bcontroller%5D=Speiseplan&cHash=c17db9c6513c97243f2ff16086a7d191'

today = Date.today
tomorrow = today + 1

def format_date(date)
  date.strftime '%d.%m.'
end

def menu_for(date, site)
  site.css("div[data-day~='#{ format_date date }'] .menu").map do |e|
    {
      label: e.css('.left .title').text.strip,
      count: e.css('.price').attr('data-bed').value
    }
  end
end

SCHEDULER.every '10m', first_in: 0 do
  site = Nokogiri::HTML(open(url))

  data = []
  data << {label: 'Today', items: menu_for(today, site)} if !(today.saturday? || today.sunday?)
  data << {label: 'Tomorrow', items: menu_for(tomorrow, site)} if !(tomorrow.saturday? || tomorrow.sunday?)

  send_event 'mensateria', data: data
end
