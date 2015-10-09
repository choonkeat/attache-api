require 'test_helper'
require "httpclient"
require "fastimage"
require "json"

class Attache::API::TestV1 < Minitest::Test
  include Attache::API::V1

  def test_auth_options
    options = attache_auth_options
    if ATTACHE_SECRET_KEY
      assert options[:uuid]
      assert options[:hmac]
      assert options[:expiration] > Time.now.to_i
    else
      assert_equal Hash.new, options
    end
  end

  def test_attache_options
    geometry = '800x600'
    current_value = ['{"key": "value"}']
    modifiers = { placeholder: rand.to_s, data: { key: "value" }, auth_options: false }

    options = attache_options(geometry, current_value, modifiers)

    assert_equal Hash({
      data: {
        geometry: geometry,
        value: [*current_value],
        placeholder: [*modifiers[:placeholder]],
        uploadurl: ATTACHE_UPLOAD_URL,
        downloadurl: ATTACHE_DOWNLOAD_URL,
        key: "value",
      },
    }), options
  end

  if ENV['ATTACHE_URL']

    def test_upload
      assert_equal "Exãmple _1.234 _20.jpg", File.basename(@uploaded['path']), "should encode filenames"
      assert_equal 'image/jpeg', @uploaded['content_type']
      assert_equal '4x3', @uploaded['geometry'], "should detect auto-oriented geometry"
      assert_equal 425, @uploaded['bytes']
    end

    def test_delete
      response = attache_delete(@uploaded['path'])
      assert_equal "", response, "should respond with empty string when there are no errors"
    end

    def test_download_remote
      assert_equal 200, remote_response.code

      attache_delete(@uploaded['path'])
      assert_equal 404, remote_response.code, "should be removed after :attache_delete"
    end

    def test_url_for
      target_url = [
        ATTACHE_DOWNLOAD_URL,
        File.dirname(@uploaded['path']),
        CGI.escape('100x200>'),
        CGI.escape(File.basename @uploaded['path']),
      ].join('/')
      assert_equal target_url, attache_url_for(@uploaded['path'], '100x200>'), "should format as <url><path><geometry><basename.ext>"
    end

    def test_download_original
      response = HTTPClient.get attache_url_for(@uploaded['path'], 'original')
      assert_equal 200, response.code
      assert_equal IO.binread("test/fixtures/Exãmple %1.234 %20.jpg"), response.body
    end

    def test_download_auto_orient_resize
      width, height = FastImage.size attache_url_for(@uploaded['path'], '<4x')
      assert_equal 4, width
      assert_equal 3, height
    end

    def setup
      string = attache_upload(File.open "test/fixtures/Exãmple %1.234 %20.jpg")
      @uploaded = JSON.parse(string)
    rescue Exception
      puts $!
      puts $@
      puts @uploaded.inspect
      raise
    end

    def teardown
      attache_delete(@uploaded['path'])
    rescue Exception
      puts $!
      puts $@
      puts @uploaded.inspect
      raise
    end

    def remote_response
      response = HTTPClient.get attache_url_for(@uploaded['path'], 'remote')
      assert_equal 302, response.code
      assert response.headers['Location']

      sleep 10

      HTTPClient.get response.headers['Location']
    end

  end
end
