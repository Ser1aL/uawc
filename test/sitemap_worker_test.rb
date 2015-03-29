require_relative './autorun'

require 'pry'

class UrlTest < MiniTest::Test
  def test_array_unique_join
    doc = Nokogiri::HTML::DocumentFragment.parse <<-FRAGMENT
      <a href='http://example.com/link_a'>a</a>
      <a href='http://example.com/link_a'>a_copy</a>
      <a href='http://example.com/link_b'>b</a>
      <a href='http://example.com/link_c'>c</a>
      <a href='http://example.com/link_c'>c</a>
      <a href='http://example.com/link_d'>c</a>
      <a href='http://example.com/link_ff'>c</a>
    FRAGMENT

    urls = doc.css('a').map do |node_element|
      Parser::Url.new(dom_object: node_element, origin_uri: URI('http://example.com'))
    end
    array_one = [urls[0], urls[3]]
    array_two = urls[1..3] + urls[5..6]

    assert_equal 5, SitemapWorker.send(:unique_url_arrays_join, array_one, array_two).count
  end

end