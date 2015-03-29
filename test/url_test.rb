require_relative './autorun'

require 'pry'

class UrlTest < MiniTest::Test
  def setup
    @origin_uri = URI('https://github.com')
    @valid_http_url = 'http://github.com/explore'
    @valid_https_url = 'https://github.com/explore'
    @short_url = '/explore'
    @blank_url = ''
    @fragment_url = '#fragment'
    @external_url = 'http://google.com'
    @invalid_url = 'abcd'
    @xml_url = 'https://github.com/opensearch.xml'
    @image_url = 'https://github.com/apple-touch-icon-114.png'
    @archive_url = 'https://github.com/source.tar.gz'
    @short_image_url = '/apple-touch-icon-114.png'
  end

  def test_should_have_valid_href
    assert_equal nil, Parser::Url.new(dom_object: initialize_element(@invalid_url), origin_uri: '').href
    assert_equal @valid_https_url,
      Parser::Url.new(dom_object: initialize_element(@valid_https_url), origin_uri: @valid_https_url).href.to_s
  end

  def test_ignore_files
    # images should be accepted
    url = Parser::Url.new(dom_object: initialize_element(@image_url), origin_uri: @origin_uri)
    url.instance_variable_set :@valid, true
    url.send :validate_extension
    assert_equal true, url.valid?

    # xml files should be accepted
    url = Parser::Url.new(dom_object: initialize_element(@xml_url), origin_uri: @origin_uri)
    url.instance_variable_set :@valid, true
    url.send :validate_extension
    assert_equal true, url.valid?

    # arhives should be ignored
    url = Parser::Url.new(dom_object: initialize_element(@archive_url), origin_uri: @origin_uri)
    url.instance_variable_set :@valid, true
    url.send :validate_extension
    assert_equal false, url.valid?
  end

  def test_link_expansion
    url = Parser::Url.new(dom_object: initialize_element(@short_url), origin_uri: @origin_uri)

    assert_equal @valid_https_url, url.href.to_s
  end

  def test_origin_validation
    # short urls
    url = Parser::Url.new(dom_object: initialize_element(@short_url), origin_uri: @origin_uri)
    url.validate! @origin_uri
    assert_equal true, url.valid?

    # full urls
    url = Parser::Url.new(dom_object: initialize_element(@valid_https_url), origin_uri: @origin_uri)
    url.validate! @origin_uri
    assert_equal true, url.valid?

    # http vs https
    url = Parser::Url.new(dom_object: initialize_element(@valid_http_url), origin_uri: @origin_uri)
    url.validate! @origin_uri, true
    assert_equal false, url.valid?

    # http vs https, scheme rule is not strict
    url = Parser::Url.new(dom_object: initialize_element(@valid_http_url), origin_uri: @origin_uri)
    url.validate! @origin_uri, false
    assert_equal true, url.valid?
  end


  def test_should_remove_fragment
    url = Parser::Url.new(dom_object: initialize_element(@fragment_url), origin_uri: @origin_uri)
    url.validate! @origin_uri
    assert_equal false, url.href.to_s.end_with?('#fragment')
  end

  private

  def initialize_element(link, text = 'custom text')
    doc = Nokogiri::HTML::DocumentFragment.parse <<-FRAGMENT
      <a href='#{link}'>#{text}</a>
    FRAGMENT

    doc.css('a').first
  end

end