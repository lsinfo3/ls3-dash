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
        randomNum = Random.rand(1..nbQuotes)

        # Retrieve one random post
        http = Net::HTTP.new("api.tumblr.com")
        response = http.request(Net::HTTP::Get.new("/v2/blog/#{tumblrUri}/posts/quote?api_key=#{tumblrToken}&offset=#{randomNum}&limit=1"))
        if Net::HTTPSuccess
            data = JSON.parse(response.body)
            send_event('quote', { title: data["response"]["posts"][0]["photo"], photo: data["response"]["posts"][0]["source"], moreinfo: tumblrUri})
        end
    end
end