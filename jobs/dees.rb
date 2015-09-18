require 'nokogiri'
require 'open-uri'
require 'yomu'

# monkeypatch a deeper to_json in Struct
class Struct
  def to_h
    Hash[ self.members.zip(self.to_a) ]
  end
end

Dish = Struct.new 'Dish', :name, :price
Day = Struct.new 'Day', :dishes
Menu = Struct.new 'Menu', :days

SCHEDULER.every '10m', first_in: 0 do
  site = Nokogiri::HTML(open('http://www.metzgerei-dees.de/'))
  menu_plan_url = site.css('#menu-main-nav li:last a').last.attr('href')
  menu_plan = Yomu.new(URI.encode(menu_plan_url)).text

  current_dish = nil
  current_day = nil
  days = %w(monday thuesday wednesday thursday friday).each
  menu = Menu.new({})

  current_line = 0

  menu_plan.each_line.drop_while { |line| not /Menüplan/ =~ line }.drop(2).each do |line|
    break if /Änderungen vorbehalten/ =~ line

    line.strip!
    if current_line == 0
      current_day = Day.new []
    elsif current_line == 2 || current_line == 7
      current_dish = Dish.new line
    elsif current_line == 3 || current_line == 8
      current_dish.name += " #{ line }"
    elsif current_line == 5 || current_line == 10
      current_dish.price = line
    elsif current_line == 6 || current_line == 11
      current_day.dishes << current_dish
    end

    if current_line == 11
      menu.days[days.next] = current_day
      current_line = -1
    end

    current_line += 1
  end

  send_event('dees', menu: menu)
end
