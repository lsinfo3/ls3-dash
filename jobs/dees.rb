require 'nokogiri'
require 'open-uri'
require 'yomu'
require 'date'

SCHEDULER.every '10m', first_in: 0 do
  site = Nokogiri::HTML(open('http://www.metzgerei-dees.de/'))
  menu_plan_url = site.css('#menu-main-nav li:last a').last.attr('href')
  next if !menu_plan_url.downcase.end_with? "pdf"
  menu_plan = Yomu.new(URI.encode(menu_plan_url)).text

  today = Date.today
  tomorrow = today + 1

  current_dish = nil
  current_day = nil
  days = %w(monday tuesday wednesday thursday friday).each
  menu = []

  current_line = 0

  menu_plan.each_line.drop_while { |line| not /plan/ =~ line }.drop(2).each do |line|
    break if /vorbehalten/ =~ line

    line.strip!
    if current_line == 0
      current_day = { items: [] }
    elsif current_line == 2 || current_line == 7
      current_dish = { label: line }
    elsif current_line == 3 || current_line == 8
      current_dish[:label] += " #{ line }"
    elsif current_line == 5 || current_line == 10
      current_dish[:count] = line
    elsif current_line == 6 || current_line == 11
      current_day[:items] << current_dish
    end

    if current_line == 11
      current_day[:label] = days.next.titlecase
      menu << current_day
      current_line = -1
    end

    current_line += 1
  end

  relevant_menus = menu.each_with_index.select { |entry, index|
    (index + 1 == today.wday) || (index + 1 == tomorrow.wday)
  }.map { |entry, index| entry }

  relevant_menus = {empty: 'no special offers today'} if (relevant_menus.empty? && !today.sunday?)

  send_event('dees', data: relevant_menus)
end
