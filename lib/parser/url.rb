module Parser
  class Url
    EXTENSION_WHITELIST = %w[ade adp bat chm cmd
      com cpl css exe hta ins isp jse js lib lnk mde msc
      msp mst pif scr sct shb sys vb vbe vbs vxd wsc wsf
      wsh zip tar tgz taz z gz rar
    ]
    @logger = File.open('log/url_logger.log', 'a+')

    attr_reader :href

    def initialize(dom_object:, origin_uri:)
      begin
        @valid = false
        @href = URI.join(origin_uri, URI(dom_object.attributes['href'].to_s))
      rescue => exception
        Url.logger.puts exception.message
        return nil
      end
    end

    def validate!(origin_uri, strict_scheme = false)
      @valid = true

      validate_origin(origin_uri, strict_scheme)
      validate_extension

      remove_fragment! if valid?
    end

    def valid?
      @valid
    end

    private

    def validate_origin(origin_uri, strict_scheme)
      return false unless valid?

      begin
        if strict_scheme
          if @href.host != origin_uri.host || @href.scheme != origin_uri.scheme
            @valid = false
          end
        else
          @valid = false if @href.host != origin_uri.host
        end
      rescue
        return @valid = false
      end
    end

    def validate_extension
      return false unless valid?

      @valid = EXTENSION_WHITELIST.none? do |file_extension|
        @href.path.to_s.end_with?(".#{file_extension.downcase}")
      end
    end

    def remove_fragment!
      @href.fragment = nil
    end

    def self.logger
      @logger
    end
  end
end