require 'sinatra/base'
require 'sinatra/reloader'
require 'resque'
require 'json'
require 'mail'

require_relative './lib/util'
require_relative './lib/parser/page'
require_relative './lib/parser/url'
require_relative './lib/generator/generator'
require_relative './workers/sitemap_worker'

class UAWC < Sinatra::Base
  run! if app_file == $0

  configure do
    register Sinatra::Reloader
    set :server, :puma
    set :haml, { :format => :html5 }
  end

  get '/' do
    haml :index, layout: :'layouts/application'
  end

  post '/generate' do
    content_type :json

    if params[:additional][:delivery_type] == 'email' && (params[:additional][:email].nil? || params[:additional][:email].empty?)
      return { error: 'Email is empty' }.to_json
    end

    if params[:site_url] !~ URI::regexp
      return { error: 'Site URL is not valid' }.to_json
    end

    site_url = URI(params[:site_url])

    # preserve trailing slash if that's the only path received
    # otherwise - reduce path to root without slash
    if site_url.path == '/'
      site_url = URI.join(params[:site_url], '/')
    else
      site_url = URI(params[:site_url])
      site_url.path = ''
      site_url = site_url.to_s
    end

    submission_key = Digest::SHA2.hexdigest(Time.now.to_f.to_s)[0..6]
    UAWC.application_redis.set submission_key, { status: 'pending' }.to_json
    response = { submission_key: submission_key }

    Resque.enqueue SitemapWorker, { submission_key: submission_key, site_url: site_url.to_s, additional: params[:additional] }

    response.to_json
  end

  post '/get_status' do
    submission = JSON.parse(UAWC.application_redis.get params[:key])

    response = {}
    if submission['status'] == 'complete'
      response = {sitemap: submission['sitemap'], email_sent: submission['delivery_performed']}
    end

    content_type :json
    response.to_json
  end

  get '/get_file/:name' do
    send_file File.expand_path(File.join('public', 'sitemaps', params[:name])), filename: params[:name], type: 'application/x-gzip'
  end

  def self.application_redis
    @redis ||= Redis.new(:host => "127.0.0.1", :port => 6379, :db => 1)
  end

end

Resque.redis = Redis.new(:host => "127.0.0.1", :port => 6379, :db => 0)
