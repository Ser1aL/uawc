gem 'minitest'

require_relative '../lib/util'
require_relative '../lib/parser/page'
require_relative '../lib/parser/url'
require_relative '../lib/generator/generator'
require_relative '../workers/sitemap_worker'

require 'mail'
require 'minitest/autorun'
require 'minitest'

Minitest.autorun