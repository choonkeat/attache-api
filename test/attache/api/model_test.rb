require 'test_helper'

class Attache::API::TestModel < Minitest::Test
  include Attache::API::Model

  def test_attache_field_options
    assert_equal Hash({
      data: {
        geometry: "geometry123",
        value: [ {"path" => "dirname456/value789", "url" => "#{Attache::API::V1::ATTACHE_DOWNLOAD_URL}/dirname456/geometry123/value789" } ],
        placeholder: ["placeholder"],
        uploadurl: Attache::API::V1::ATTACHE_UPLOAD_URL,
        downloadurl: Attache::API::V1::ATTACHE_DOWNLOAD_URL,
        key: "value789",
      },
    }), attache_field_options(
      { "path" => "dirname456/value789" },
      "geometry123",
      { placeholder: "placeholder", data: { key: "value789" }, auth_options: false }
    )
  end

  def test_attache_field_urls
    assert_equal ["#{Attache::API::V1::ATTACHE_DOWNLOAD_URL}/dirname456/geometry123/value789"],
      attache_field_urls( { "path" => "dirname456/value789" }, "geometry123")
  end

  def test_attache_field_attributes
    assert_equal [{"path"=>"dirname456/value789", "url"=>"http://localhost:9292/view/dirname456/geometry123/value789"}],
      attache_field_attributes( { "path" => "dirname456/value789" }, "geometry123")
  end

  def test_attache_field_set
    assert_equal [{"path"=>"dirname456/value789"}],
      attache_field_set([{}, "", {"path" => "dirname456/value789"}, nil])
  end

  def test_attache_mark_for_discarding
    attaches_discarded = []
    attache_mark_for_discarding([{}, "", {"path" => "dirname456/value789"}, nil, {"path" => "dirname456/value7892"}], [{"path" => "dirname456/value7892"}], attaches_discarded)
    assert_equal ["dirname456/value789"], attaches_discarded
  end

  def test_attaches_discard
    assertion = -> (uri, params) {
      assert_equal URI.parse(Attache::API::V1::ATTACHE_DELETE_URL), uri
      assert_equal "one\ntwo\nthree", params[:paths]
    }
    HTTPClient.stub(:post_content, assertion) do
      attaches_discard!(["one", nil, "two", "", "three"])
    end
  end
end
