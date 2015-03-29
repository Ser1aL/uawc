require 'nokogiri'
require 'open-uri'
require 'open_uri_redirections'
require 'socket'
require 'timeout'

module Parser
  class Page
    @logger = File.open('log/page_logger.log', 'a+')

    def initialize(page_url, configuration = {})
      begin
        @page_uri = URI(page_url)
        @strict_scheme = configuration['strict_scheme_rule'].to_i == 1
      rescue URI::InvalidURIError
        return nil
      end
      @internal_links = []
    end

    def links
      @internal_links
    end

    def parse!
      page_contents = open_remote(@page_uri)
      return unless page_contents && page_contents.is_a?(Nokogiri::HTML::Document)

      page_contents.css('a[href]').each do |dom_object|
        url_object = Url.new(dom_object: dom_object, origin_uri: @page_uri)
        url_object.validate!(@page_uri, @strict_scheme) if url_object.href

        unique_push url_object if url_object.valid?
      end
    end

    private

    def open_remote(url)
      begin
        Page.logger.puts url

        iostream = nil
        begin
          Timeout::timeout(3) { iostream = open(url, allow_redirections: :safe) }
        rescue Timeout::Error
          return 'Timeout opening page'
        end

        # validate if page is 200 OK
        return 'Response code is not 200 OK' if iostream.status != ['200', 'OK']

        # validate mime-type
        return 'Is not valid HTML document' if iostream.content_type != 'text/html'

        Nokogiri::HTML(iostream)
      rescue Errno::ENOENT
        'Root url is invalid'
      rescue SocketError
        'Domain name is incorrect or is unknown'
      rescue OpenURI::HTTPError
        'Page not found or internal server error'
      rescue Errno::ECONNREFUSED
        'Connection refused'
      rescue RuntimeError
        'Redirection is forbidden (https -> http)'
      rescue
        'Unknown error'
      end
    end

    def unique_push(url_object)
      unless @internal_links.map(&:href).map(&:to_s).include?(url_object.href.to_s)
        @internal_links << url_object
      end
    end

    def self.logger
      @logger
    end

  end
end