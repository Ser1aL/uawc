class SitemapWorker
  @queue = :sitemap_queue

  include Parser
  extend Generator

  # 0 means root page only
  MAX_DEEP_LEVEL = 1

  class << self
    def perform(*args)
      start_time = Time.now.to_f
      @visited_links = []
      if args.first['additional'].nil? || args.first['additional'].empty?
        @configuration = {}
      else
        @configuration = args.first['additional']
      end
      @active_threads_count = 0

      collected_urls = collect_urls(source_url: args.first['site_url'], submission_key: args.first['submission_key'])

      sitemap_archive = generate_sitemap_archive(collected_urls, args.first['site_url'])

      if @configuration['delivery_type'] == 'email'
        sent = email_file(sitemap_archive, @configuration['email'])
      end

      application_redis.set args.first['submission_key'], {
        status: 'complete',
        sitemap: sitemap_archive,
        delivery_performed: sent
      }.to_json
    end

    def collect_urls(urls: [], source_url:, deep_level: 0, submission_key:)
      deep_level += 1

      save_visit(source_url)
      page = Parser::Page.new(source_url, @configuration)
      page.parse!
      urls += page.links

      if deep_level < MAX_DEEP_LEVEL + 1
        threads = []
        page.links.each do |url|
          unless already_visited?(url.href.to_s)
            threads << Thread.new do
              new_url_objects = collect_urls(urls: urls, source_url: url.href.to_s, deep_level: deep_level, submission_key: submission_key)
              urls = unique_url_arrays_join(urls, new_url_objects)
            end
          end
        end

        begin
          threads.each(&:join)
        rescue ThreadError
        end
      end

      urls
    end

    def email_file(gzfile, recipient)
      smtp_settings = {
        :address              => "smtp.gmail.com",
        :port                 => 587,
        :user_name            => "teachme.notifier@gmail.com",
        :password             => "teachme.notifier",
        :authentication       => "plain",
        :enable_starttls_auto => true
      }

      Mail.defaults do
        delivery_method :smtp, smtp_settings
      end

      begin
        Mail.deliver do
          to recipient
          from 'uawc-crawler@uawc-crawler.com'
          subject 'Your sitemap has successfully been generated. Rename to .tar.gz'
          body 'Your sitemap has successfully been generated'
          attachments[gzfile] = File.read(File.expand_path(File.join('public', 'sitemaps', gzfile)))
        end

        true
      rescue => exception
        false
      end
    end

    def already_visited?(link)
      @visited_links.include?(link)
    end

    def save_visit(link)
      @visited_links << link
    end

    def unique_url_arrays_join(array_one, array_two)
      array_links = array_one.map(&:href).map(&:to_s)

      array_one += array_two.select do |url_object|
        !array_links.include?(url_object.href.to_s)
      end
    end

    def application_redis
      @redis ||= Redis.new(:host => "127.0.0.1", :port => 6379, :db => 1)
    end

  end # class << self
end # class