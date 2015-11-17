require 'nokogiri'
require 'open-uri'
require 'yomu'
require 'date'

SCHEDULER.every '10m', first_in: 0 do
  site = Nokogiri::HTML(open('http://www.metzgerei-dees.de/'))
  menu_plan_url = site.css('#menu-main-nav li:last a').last.attr('href')
  next if !menu_plan_url.downcase.end_with? "xps"

  # XPS convert
  File.open('/tmp/_tmp_dees.xps', "wb") do |file|
	    file.write open(URI.encode(menu_plan_url)).read
  end
  `xpstopdf /tmp/_tmp_dees.xps /tmp/_tmp_dees.pdf`  #  apt-get install libgxps-utils
  menu_plan = Yomu.new('/tmp/_tmp_dees.pdf').text

  days = %w(Montag, Dienstag, Mittwoch, Donnerstag, Freitag).each
  today = Date.today
  tomorrow = today + 1

  current_day = nil
  current_dish = { label: "" }
  menu = []

  menu_plan.each_line.drop_while { |line| not /plan/ =~ line }.drop(2).each do |line|
    break if /en Sie die M/ =~ line

    line.strip!
    
    if line =~ /Montag|Dienstag|Mittwoch|Donnerstag|Freitag/ 
      menu << current_day if !current_day.nil?
      current_day = { label: line, items: [] }
    elsif line =~ /[0-9]+,[0-9][0-9]+/
      current_dish[:count] = line
      current_day[:items] << current_dish 
      current_dish = { label: "" }
    else
      line[0] = line[0].chr.downcase if !line.empty? && !current_dish[:label].strip.empty?
      current_dish[:label] += " #{line}"
    end

  end
  menu << current_day

  relevant_menus = menu.each_with_index.select { |entry, index|
    (index + 1 == today.wday) || (index + 1 == tomorrow.wday)
  }.map { |entry, index| entry }

  relevant_menus = {empty: 'no special offers today'} if (relevant_menus.empty? && !today.sunday?)

  send_event('dees', data: relevant_menus)
end
