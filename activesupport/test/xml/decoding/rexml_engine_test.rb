require 'abstract_unit'
require 'active_support/xml'

class REXMLEngineTest < Test::Unit::TestCase
  include ActiveSupport

  def test_set_rexml_as_backend
    ActiveSupport::Xml.backend = 'REXML'
    assert_equal MultiXml::Parsers::Rexml, ActiveSupport::Xml.backend
  end

  def test_parse_from_io
    ActiveSupport::Xml.backend = 'REXML'
    io = StringIO.new(<<-eoxml)
    <root>
      good
      <products>
        hello everyone
      </products>
      morning
    </root>
    eoxml
    ActiveSupport::Xml.decode(io)
  end
end
