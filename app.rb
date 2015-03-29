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

  get '/' do #:nodoc:
    haml :index, layout: :'layouts/application'
  end

  # == Generate action
  #
  # Users land here when submit the form. Action does basic santization:
  # valides if site_url is matches URI::regexp and if email at least exists.
  # It also removes the path from user input to be sure Resque works with
  # the root page. If user specified a site that ends with '/', consider it a
  # valid url and don't change it. Urls with and without trailing slashes are
  # different endpoints: http://googlewebmastercentral.blogspot.com/2010/04/to-slash-or-not-to-slash.html
  #
  # After basic sanitization this action runs resque worker to generate,
  # build and deliver sitemap
  post '/generate' do
    content_type :json

    if params[:additional][:delivery_type] == 'email' && (params[:additional][:email].nil? || params[:additional][:email].empty?)
      return { error: 'Email is empty' }.to_json
    end

    if params[:site_url] !~ URI::regexp
      return { error: 'Site URL is not valid' }.to_json
    end

    site_url = URI(params[:site_url])

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

  # == Get status action
  #
  # Respond to ajax call to get the status of request from Redis
  # If request is complete return file path or delivery message
  post '/get_status' do
    submission = JSON.parse(UAWC.application_redis.get params[:key])

    response = {}
    if submission['status'] == 'complete'
      response = {sitemap: submission['sitemap'], email_sent: submission['delivery_performed']}
    end

    content_type :json
    response.to_json
  end

  # == Get file action
  #
  # Download file preserving the mime-type
  get '/get_file/:name' do
    send_file File.expand_path(File.join('public', 'sitemaps', params[:name])), filename: params[:name], type: 'application/x-gzip'
  end

  def self.application_redis #:nodoc:
    @redis ||= Redis.new(:host => "127.0.0.1", :port => 6379, :db => 1)
  end

end

Resque.redis = Redis.new(:host => "127.0.0.1", :port => 6379, :db => 0)
