require 'securerandom'
require "httpclient"
require 'openssl'
require 'uri'
require 'cgi'

module Attache
  module API
    module V1
      class HTTPClient < ::HTTPClient; end # local reference

      ATTACHE_URL             = ENV.fetch('ATTACHE_URL')             { "http://localhost:9292" }
      ATTACHE_UPLOAD_URL      = ENV.fetch('ATTACHE_UPLOAD_URL')      { "#{ATTACHE_URL}/upload" }
      ATTACHE_DOWNLOAD_URL    = ENV.fetch('ATTACHE_DOWNLOAD_URL')    { "#{ATTACHE_URL}/view" }
      ATTACHE_DELETE_URL      = ENV.fetch('ATTACHE_DELETE_URL')      { "#{ATTACHE_URL}/delete" }
      ATTACHE_BACKUP_URL      = ENV.fetch('ATTACHE_BACKUP_URL')      { "#{ATTACHE_URL}/backup" }
      ATTACHE_UPLOAD_DURATION = ENV.fetch('ATTACHE_UPLOAD_DURATION') { 3*3600 }.to_i # expires signed upload form
      ATTACHE_SECRET_KEY      = ENV['ATTACHE_SECRET_KEY']            # unset to test password-less interaction

      def attache_upload(readable)
        uri = URI.parse(ATTACHE_UPLOAD_URL)
        original_filename =
          readable.respond_to?(:original_filename) && readable.original_filename ||
          readable.respond_to?(:path) && File.basename(readable.path) ||
          'noname'
        uri.query = { file: original_filename, **attache_auth_options }.collect {|k,v|
          CGI.escape(k.to_s) + "=" + CGI.escape(v.to_s)
        }.join('&')
        res = attache_retry_doing(3) { HTTPClient.post(uri, readable, {'Content-Type' => 'binary/octet-stream'}) }
        res.body
      end

      def attache_url_for(path, geometry)
        prefix, basename = File.split(path)
        [ATTACHE_DOWNLOAD_URL, prefix, CGI.escape(geometry), CGI.escape(basename)].join('/')
      end

      def attache_delete(*paths)
        HTTPClient.post_content(
          URI.parse(ATTACHE_DELETE_URL),
          attache_auth_options.merge(paths: paths.join("\n"))
        )
      end

      def attache_backup(*paths)
        HTTPClient.post_content(
          URI.parse(ATTACHE_BACKUP_URL),
          attache_auth_options.merge(paths: paths.join("\n"))
        )
      end

      def attache_auth_options
        if ATTACHE_SECRET_KEY
          uuid = SecureRandom.uuid
          expiration = (Time.now + ATTACHE_UPLOAD_DURATION).to_i
          hmac = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), ATTACHE_SECRET_KEY, "#{uuid}#{expiration}")
          { uuid: uuid, expiration: expiration, hmac: hmac }
        else
          {}
        end
      end

      def attache_options(geometry, current_value, auth_options: true, placeholder: nil, data: {})
        {
          data: {
            geometry: geometry,
            value: [*current_value],
            placeholder: [*placeholder],
            uploadurl: ATTACHE_UPLOAD_URL,
            downloadurl: ATTACHE_DOWNLOAD_URL,
          }.merge(data || {}).merge(auth_options == false ? {} : attache_auth_options),
        }
      end

      def attache_retry_doing(max_retries, retries = 0, exception_class = Exception)
        yield
      rescue exception_class
        if (retries += 1) <= max_retries
          max_sleep_seconds = Float(2 ** retries)
          sleep rand(0..max_sleep_seconds)
          retry
        end
        raise
      end

      def attache_signature_for(hash)
        if ATTACHE_SECRET_KEY.to_s.strip != ""
          hash_without_signature = hash.reject {|k,v| k == 'signature' }
          content = hash_without_signature.sort.collect {|k,v| "#{k}=#{v}" }.join('&')
          generated_signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), ATTACHE_SECRET_KEY, content)
          yield generated_signature if block_given?
          generated_signature
        end
      end

      self.extend(self)
    end
  end
end
