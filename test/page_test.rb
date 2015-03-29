require_relative './autorun'

require 'pry'

class PageTest < MiniTest::Test
  def setup
    @blank_page = Parser::Page.new('')
  end

  def test_should_initialize_correctly_with_incorrect_url
    assert_equal nil, Parser::Page.new('http://localhost:aa').instance_variable_get(:@page_uri)
  end

  def test_valid_url
    assert_equal 'Root url is invalid', @blank_page.send(:open_remote, 'abcde')
  end

  def test_invalid_domain
    assert_equal 'Domain name is incorrect or is unknown', @blank_page.send(:open_remote, 'http://abcde')
  end

  def test_not_found_and_server_errors
    assert_equal 'Page not found or internal server error', @blank_page.send(:open_remote, 'https://github.com/a1233ddasd123123')
  end

  def test_connection_refused
    assert_equal 'Connection refused', @blank_page.send(:open_remote, 'https://localhost:8723')
  end

  def test_redirections
    # https -> http is forbidden
    assert_equal "Redirection is forbidden (https -> http)", @blank_page.send(:open_remote, 'https://intel.xcal.tv')

    # http -> https is allowed
    assert_kind_of Nokogiri::HTML::Document, @blank_page.send(:open_remote, 'http://github.com')
  end

  def test_should_validate_mime_type
    assert_kind_of Nokogiri::HTML::Document, @blank_page.send(:open_remote, 'https://www.google.com.ua')
    assert_equal "Is not valid HTML document", @blank_page.send(:open_remote, 'https://www.google.com.ua/images/srpr/logo11w.png')
    assert_equal "Is not valid HTML document", @blank_page.send(:open_remote, 'http://a.disquscdn.com/embed.js')
  end

  def test_unique_push
    doc = Nokogiri::HTML::DocumentFragment.parse <<-FRAGMENT
      <a href='http://example.com/link_a'>a</a>
      <a href='http://example.com/link_a'>a_copy</a>
      <a href='http://example.com/link_b'>b</a>
      <a href='http://example.com/link_c'>c</a>
    FRAGMENT

    doc.css('a').map do |node_element|
      @blank_page.send :unique_push, Parser::Url.new(dom_object: node_element, origin_uri: URI('http://example.com'))
    end

    assert_equal 3, @blank_page.links.count
    setup
  end

  def test_it_should_work
    page = Parser::Page.new('https://thoughtbot.com')
    page.parse!

    assert_equal 11, page.links.count
  end
end