require 'test_helper'

class Attache::API::TestModel < Minitest::Test
  include Attache::API::Model

  def with_secret_key(value)
    old_value = Attache::API::V1::ATTACHE_SECRET_KEY && Attache::API::V1::ATTACHE_SECRET_KEY.dup
    Attache::API::V1.send(:remove_const, :ATTACHE_SECRET_KEY)
    Attache::API::V1.send(:const_set, :ATTACHE_SECRET_KEY, value)
    yield value
  ensure
    Attache::API::V1.send(:remove_const, :ATTACHE_SECRET_KEY)
    Attache::API::V1.send(:const_set, :ATTACHE_SECRET_KEY, old_value)
  end

  def test_attache_field_options
    with_secret_key "" do
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
  end

  def test_attache_field_urls
    with_secret_key "" do
      assert_equal ["#{Attache::API::V1::ATTACHE_DOWNLOAD_URL}/dirname456/geometry123/value789"],
        attache_field_urls( { "path" => "dirname456/value789" }, "geometry123")
    end
  end

  def test_attache_field_attributes_without_secret_but_has_signature
    with_secret_key "" do
      assert_equal [{"path"=>"dirname456/value789", "url"=>"#{Attache::API::V1::ATTACHE_URL}/view/dirname456/geometry123/value789"}],
        attache_field_attributes( { "path" => "dirname456/value789", "signature" => "lorem ipsum" }, "geometry123")
    end
  end

  def test_attache_field_attributes_without_secret
    with_secret_key "" do
      assert_equal [{"path"=>"dirname456/value789", "url"=>"#{Attache::API::V1::ATTACHE_URL}/view/dirname456/geometry123/value789"}],
        attache_field_attributes( { "path" => "dirname456/value789" }, "geometry123")
    end
  end

  def test_attache_field_attributes_with_secret
    with_secret_key "topsecret" do |secret_key|
      hash_without_signature = { "path"=>"dirname456/value789", "url"=>"#{Attache::API::V1::ATTACHE_URL}/view/dirname456/geometry123/value789" }
      content = hash_without_signature.sort.collect {|k,v| "#{k}=#{v}" }.join('&')
      valid_signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), secret_key, content)
      assert_equal [hash_without_signature.merge("signature" => valid_signature)],
        attache_field_attributes( { "path" => "dirname456/value789" }, "geometry123")
    end
  end

  def test_attache_field_set_without_secret
    with_secret_key "" do
      assert_equal [{"path"=>"dirname456/value789"}],
        attache_field_set([{}, "", {"path" => "dirname456/value789"}, nil])
    end
  end

  def test_attache_field_set_with_secret_valid_signature
    with_secret_key "topsecret" do |secret_key|
      valid_signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), secret_key, 'path=dirname456/value789')
      assert_equal [{"path"=>"dirname456/value789"}],
        attache_field_set([{"path" => "dirname456/value789", "signature" => valid_signature}])
    end
  end

  def test_attache_field_set_with_secret_invalid_signature
    with_secret_key "topsecret" do |secret_key|
      assert_equal [],
        attache_field_set([{"path" => "dirname456/value789", "signature" => "wrong"}])
    end
  end

  def test_attache_update_pending_diffs
    pending_backup = []
    pending_discard = []
    attache_update_pending_diffs([{}, "", {"path" => "dirname456/value789"}, nil, {"path" => "dirname456/value7892"}], [{"path" => "dirname456/value7892"}, "", nil, {}, {"path" => "dirname789/value987"}], pending_backup, pending_discard)
    assert_equal ["dirname789/value987"], pending_backup
    assert_equal ["dirname456/value789"], pending_discard
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

  def test_attaches_backup
    assertion = -> (uri, params) {
      assert_equal URI.parse(Attache::API::V1::ATTACHE_BACKUP_URL), uri
      assert_equal "one\ntwo\nthree", params[:paths]
    }
    HTTPClient.stub(:post_content, assertion) do
      attaches_backup!(["one", nil, "two", "", "three"])
    end
  end
end
