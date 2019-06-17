#!/usr/bin/env ruby
require 'net/http'
require 'net/http/oauth'
require 'open-uri'
require 'nokogiri'
require 'json'
require 'htmlentities'

tumblrUri = 'ls3photos.tumblr.com' # the URL of the blog on Tumblr, ex: inspire.niptech.com
oauth_consumer_key =    '0JqbvujVVKwRbyO9F2snB7JqVXk8Yzt1VT0vfdw6mC2pbC0Znz'
oauth_consumer_secret = 'GEsZsq0YwzKHZfJPQUCOTqAN9QYSiyWKKfewk5B55BRJARJz7P'
oauth_token =           'b24EtHEDy9vLTKb4TzqOqUJLN0VCbbzGOd5X32QnWe4kIsgoE6'
oauth_token_secret =    'LFXUlsw8787fuGQv97n8A8UM6n4MX4NrdhJzMp2Im8syQowmFw'

flickrID = '90962754@N00'

SCHEDULER.every '3m', first_in: 0 do |_job|
  http = Net::HTTP.new('api.tumblr.com', Net::HTTP.https_default_port)
  http.use_ssl = true

  get_request = Net::HTTP::Get.new("/v2/blog/#{tumblrUri}/info?api_key=#{oauth_consumer_key}")

  Net::HTTP::OAuth.sign!(http, get_request, {
    consumer_key: oauth_consumer_key,
    consumer_secret: oauth_consumer_secret,
    token: oauth_token,
    token_secret: oauth_token_secret
  })

  response = http.request(get_request)
  if response.code == '200'

    # Retrieve total number of posts
    data = JSON.parse(response.body)
    tum_photos = data['response']['blog']['posts'].to_i
    # append flickr urls at the end
    # photos = flickr_urls('public', flickrID)
    # flick_photos = photos.count
    flick_photos = 0

    all_photos = tum_photos + flick_photos
    end_pics = [all_photos, 10].min
    if (Random.rand(0..1) <= 0.1)
      randomNum = 0
      #p "-> Newest picture"
    elsif (Random.rand(0..1) <= 0.8)
      randomNum = Random.rand(1..(end_pics - 1))
      #p "-> One of the 10 newest pictures"
    else
      randomNum = Random.rand(end_pics..(all_photos - 1))
      #p "-> Random picture"
    end

    if (randomNum <= (tum_photos - 1))
      # tumblr
      # Retrieve one random post
      
      get_request = Net::HTTP::Get.new("/v2/blog/#{tumblrUri}/posts?api_key=#{oauth_consumer_key}&offset=#{randomNum}&limit=1")
      Net::HTTP::OAuth.sign!(http, get_request, {
        consumer_key: oauth_consumer_key,
        consumer_secret: oauth_consumer_secret,
        token: oauth_token,
        token_secret: oauth_token_secret
      })
      response = http.request(get_request)
      
      if Net::HTTPSuccess
        data = JSON.parse(response.body)
        media_type = data['response']['posts'][0]['type']
        #p media_type
        if (media_type == 'video')
          #p data['response']['posts'][0]['caption'].gsub(/<\/?[^>]+>/, '')
          send_event('tumblr', text: HTMLEntities.new.decode(data['response']['posts'][0]['caption']).gsub(/<\/?[^>]+>/, ''), image: data['response']['posts'][0]['video_url'], moreinfo: tumblrUri)
        elsif (media_type == "photo")
          #p data['response']['posts'][0]['caption'].gsub(/<\/?[^>]+>/, '')
          #p data['response']['posts'][0]['photos'][0]['alt_sizes'][1]['url']
          send_event('tumblr', text: HTMLEntities.new.decode(data['response']['posts'][0]['caption']).gsub(/<\/?[^>]+>/, ''), image: data['response']['posts'][0]['photos'][0]['alt_sizes'][0]['url'], moreinfo: tumblrUri)
	else 
	   #p "media type not supported: #{media_type}"	
        end
      end
    else
      # if flickr
      send_event('tumblr', text: '', image: photos[randomNum - tum_photos], moreinfo: 'flickr')
  end
 end
end

def flickr_urls(type, flickr_id)
  # https://api.flickr.com/services/feeds/photos_public.gne?id=101571970@N05
  doc = Nokogiri::HTML(open("http://api.flickr.com/services/feeds/photos_#{type}.gne?id=#{flickr_id}"))
  photos = []
  doc.css('entry link').each do |link|
    photos.push(link.attr('href')) if (link.attr('rel') == 'enclosure')
  end
  # p photos
  photos
end
