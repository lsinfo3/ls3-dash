require 'nokogiri'
require 'open-uri'
require 'date'

config = { 'mensateria' => 'https://www.studentenwerk-wuerzburg.de/wuerzburg/essen-trinken/speiseplaene.html?tx_thmensamenu_pi2%5Bmensen%5D=54&tx_thmensamenu_pi2%5Baction%5D=show&tx_thmensamenu_pi2%5Bcontroller%5D=Speiseplan&cHash=c17db9c6513c97243f2ff16086a7d191' }
#, 'mensahubland' => 'https://www.studentenwerk-wuerzburg.de/wuerzburg/essen-trinken/speiseplaene.html?tx_thmensamenu_pi2[mensen]=7&tx_thmensamenu_pi2[action]=show&tx_thmensamenu_pi2[controller]=Speiseplan&cHash=efe40abc8afe9bcac3abf914dff9d943' }

def format_date(date)
  date.strftime '%d.%m.'
end

def menu_for(date, site)
  site.css("div[data-day~='#{format_date date}'] .menu").map do |e|
    {
      icon: (e.css('.icon .theicon').attr('title').value.gsub(/\w+/, 'Fleischlos' => 'leaf') rescue ""), # Gefluegel => "twitter", Schwein => ?, Fisch => ?
      label: (e.css('.left .title').text.strip rescue ""),
      count: (e.css('.price').attr('data-bed').value rescue "")
    }
  end
end

# main
config.each do |handle, url|
  SCHEDULER.every '10m', first_in: 0 do
    site = Nokogiri::HTML(open(url, :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE))
    
    today = Date.today
    tomorrow = today + 1

    data = []
    data << { label: 'Today', items: menu_for(today, site) } unless today.saturday? || today.sunday?
    data << { label: 'Tomorrow', items: menu_for(tomorrow, site) } unless tomorrow.saturday? || tomorrow.sunday?

    send_event handle, data: data
  end
end
