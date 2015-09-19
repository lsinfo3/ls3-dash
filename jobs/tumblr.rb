#!/usr/bin/env ruby
require 'net/http'
require 'json'
 
tumblrToken = "0JqbvujVVKwRbyO9F2snB7JqVXk8Yzt1VT0vfdw6mC2pbC0Znz" # your Tumblr token/API Key (http://www.tumblr.com/docs/en/api/v2#auth)
tumblrUri = "ls3admin.tumblr.com" # the URL of the blog on Tumblr, ex: inspire.niptech.com

SCHEDULER.every '10m', :first_in => 0 do |job|
    http = Net::HTTP.new("api.tumblr.com")
    response = http.request(Net::HTTP::Get.new("/v2/blog/#{tumblrUri}/info?api_key=#{tumblrToken}"))
    if response.code == "200"
        
        # Retrieve total number of posts
        data = JSON.parse(response.body)
        nbQuotes = data["response"]["blog"]["posts"].to_i
	if (Random.rand(0..1) <= 0.3)
		randomNum = 0
	else
	        randomNum = Random.rand(0..(nbQuotes-1))
	end
	p randomNum
	
        # Retrieve one random post
        http = Net::HTTP.new("api.tumblr.com")
        response = http.request(Net::HTTP::Get.new("/v2/blog/#{tumblrUri}/posts?api_key=#{tumblrToken}&offset=#{randomNum}&limit=1"))
        if Net::HTTPSuccess
            data = JSON.parse(response.body)
	    data["response"]["posts"][0]["caption"].slice!("<p>")
	    data["response"]["posts"][0]["caption"].slice!("</p>")
	    send_event('tumblr', { text: data["response"]["posts"][0]["caption"], image: data["response"]["posts"][0]["photos"][0]["alt_sizes"][3]["url"], moreinfo: tumblrUri})
        end
    end
end
