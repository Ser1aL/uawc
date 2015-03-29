require 'builder'

module Generator
  include Util::Tar

  SITEMAPS_PATH = 'public/sitemaps'
  SITEMAP_URL_LIMIT = 1_000

  def generate_sitemap_archive(urls, origin_url)
    name_suffix = Digest::SHA2.hexdigest(Time.now.to_f.to_s)[0..2]

    directory_name = origin_url.gsub(/[^a-z0-9_]+/, '_') + '_' + name_suffix
    archive_path = File.join(SITEMAPS_PATH, directory_name + '.rename')
    Dir.mkdir File.join(SITEMAPS_PATH, directory_name)

    if urls.count > SITEMAP_URL_LIMIT
      sitemaps = []
      urls.each_slice(SITEMAP_URL_LIMIT) do |urls_slice|
        sitemaps << build_xml(urls_slice, directory_name)
      end
      build_sitemap_index(sitemaps, directory_name)
    else
      build_xml(urls, directory_name)
    end

    archive = File.open(archive_path, 'w') do |archive|
      archive.puts gzip(tar(File.join(SITEMAPS_PATH, directory_name))).read
    end

    FileUtils.rm_rf(File.join(SITEMAPS_PATH, directory_name))

    directory_name + '.rename'
  end

  def build_xml(urls, directory_name)
    filename = 'sitemap_' + Digest::SHA2.hexdigest(Time.now.to_f.to_s)[1..11] + '.xml'
    path = File.expand_path(File.join(SITEMAPS_PATH, directory_name, filename))

    output_io = File.new(path, 'w')

    xml = Builder::XmlMarkup.new(target: output_io, indent: 2)
    xml.instruct!
    xml.urlset(xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") do
      urls.each do |url_object|
        xml.url do
          xml.loc url_object.href
          xml.lastmod Time.now.utc.strftime("%Y-%m-%dT%H:%M:%S%:z")
          xml.changefreq 'always'
        end
      end
    end

    output_io.close

    filename
  end

  def build_sitemap_index(sitemaps, directory_name)
    filename = 'sitemap_index.xml'
    path = File.expand_path(File.join(SITEMAPS_PATH, directory_name, filename))

    output_io = File.new(path, 'w')

    xml = Builder::XmlMarkup.new(target: output_io, indent: 2)
    xml.instruct!
    xml.sitemapindex(xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") do
      sitemaps.each do |sitemap|
        xml.sitemap do
          xml.loc "http://example.com/#{sitemap}"
          xml.lastmod Time.now.utc.strftime("%Y-%m-%dT%H:%M:%S%:z")
        end
      end
    end

    output_io.close
  end
end