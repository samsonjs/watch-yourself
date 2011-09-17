#!/usr/bin/env ruby

require 'rubygems'
require 'bundler'
Bundler.require

def time_now
  (Time.now.to_f * 1000).to_i
end

module WatchYourself
  class Server < Sinatra::Base

    set :port, 8008

    enable :logging

    # serve static files from /public
    set :public, File.dirname(__FILE__) + '/public'

    def redis
      @redis ||= Redis.new
    end

    def key *parts
      'watch-yourself:' + (parts ? parts.join(':') : '')
    end

    get '/' do
      redirect '/in.html'
    end
  
    post '/in' do
      now = time_now
      stats = { :time => now, :sys => params['sys'], :dia => params['dia'], :pulse => params['pulse'] }
      $stderr.puts "[#{now}] IN: #{stats.inspect}"
      redis.zadd key('stats'), now, JSON.stringify(stats)
      redirect '/stats.html'
    end

    get '/stats' do
      content_type 'application/json', :charset => 'utf8'
      stats = redis.zrevrange key('stats'), 0, -1, :withscores => true
      stats ||= []
      JSON.generate(stats.map { |s| JSON.parse(s) })
    end

  end
end

if $0 == __FILE__
  WatchYourself::Server.run!
end
