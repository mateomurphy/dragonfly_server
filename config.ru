require 'rubygems'
require 'dragonfly'
require 'rack/cache'

ROOT = File.dirname(__FILE__)

class EtagCleaner
  
  def initialize(app, options = {})
    @app = app
  end
  
  def call(env)
    env.delete('HTTP_IF_NONE_MATCH')
    @app.call(env)
  end
  
  def log_headers(headers)
    headers.each do |k, v|
      puts "#{k}=#{v.inspect}"
    end
  end
end

use Rack::Cache,
  :verbose     => true,
  :metastore   => "file:#{ROOT}/tmp/cache/rack/meta",
  :entitystore => "file:#{ROOT}/tmp/cache/rack/body"

use EtagCleaner

app = Dragonfly[:images]
app.configure_with(:imagemagick)
app.configure do |c|
  c.analyser.register(Dragonfly::Analysis::FileCommandAnalyser)
  c.url_format = '/images/:job/:basename.:format'
  c.allow_fetch_url = true
  c.allow_fetch_file = false
  c.protect_from_dos_attacks = true
  c.secret = ENV['DRAGONFLY_SECRET']
end

=begin
app.datastore = Dragonfly::DataStorage::S3DataStore.new

app.datastore.configure do |c|
  c.bucket_name = ENV['AWS_BUCKET_NAME']
  c.access_key_id = ENV['AWS_ACCESS_KEY_ID']
  c.secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
end
=end

#Excon.defaults[:ssl_verify_peer] = false

#run app

require './server'
run Sinatra::Application
