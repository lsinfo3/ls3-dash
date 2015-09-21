#!/usr/bin/env ruby
require 'net/http'
require 'open-uri'
require 'nokogiri'
require 'json'


tumblrToken = "0JqbvujVVKwRbyO9F2snB7JqVXk8Yzt1VT0vfdw6mC2pbC0Znz" # your Tumblr token/API Key (http://www.tumblr.com/docs/en/api/v2#auth)
tumblrUri = "ls3admin.tumblr.com" # the URL of the blog on Tumblr, ex: inspire.niptech.com
flickrID = "90962754@N00"

SCHEDULER.every '3m', :first_in => 0 do |job|
    http = Net::HTTP.new("api.tumblr.com")
    response = http.request(Net::HTTP::Get.new("/v2/blog/#{tumblrUri}/info?api_key=#{tumblrToken}"))
    if response.code == "200"
        
        # Retrieve total number of posts
        data = JSON.parse(response.body)
        tum_photos = data["response"]["blog"]["posts"].to_i
	
	# append flickr urls at the end
        photos = flickr_urls("public", flickrID)
	flick_photos = photos.count
	flick_photos = 0;

	all_photos = tum_photos + flick_photos
	if (Random.rand(0..1) <= 0.3)
		randomNum = 0
	else
	        randomNum = Random.rand(0..(all_photos-1))
	end
	p randomNum

	if (randomNum <= (tum_photos-1))
		# tumblr
		# Retrieve one random post
	        http = Net::HTTP.new("api.tumblr.com")
        	response = http.request(Net::HTTP::Get.new("/v2/blog/#{tumblrUri}/posts?api_key=#{tumblrToken}&offset=#{randomNum}&limit=1"))
	        if Net::HTTPSuccess
        	    data = JSON.parse(response.body)
		    send_event('tumblr', { text: data["response"]["posts"][0]["caption"].gsub(/<\/?[^>]+>/, ''), image: data["response"]["posts"][0]["photos"][0]["alt_sizes"][1]["url"], moreinfo: tumblrUri})
        	end
	else
		# if flickr
		send_event('tumblr', { text: "", image: photos[randomNum - tum_photos], moreinfo: "flickr"})
	end
   end
end


def flickr_urls(type, flickr_id)
	# https://api.flickr.com/services/feeds/photos_public.gne?id=101571970@N05
	doc=Nokogiri::HTML(open("http://api.flickr.com/services/feeds/photos_#{type}.gne?id=#{flickr_id}"))
	photos = Array.new;
	doc.css('entry link').each do |link|
		if (link.attr('rel') == 'enclosure')
			photos.push(link.attr('href'))
		end
	end
	#p photos
	return photos
end
