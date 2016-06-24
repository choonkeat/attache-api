module Attache
  module API
    module Model
      def attache_field_options(attr_value, geometry, options = {})
        V1.attache_options(geometry, attache_field_attributes(attr_value, geometry), options)
      end

      def attache_field_urls(attr_value, geometry)
        attache_field_attributes(attr_value, geometry).collect {|attrs| attrs['url']}
      end

      def attache_field_attributes(attr_value, geometry)
        Utils.array(attr_value).inject([]) do |sum, obj|
          sum + Utils.array(obj && obj.tap {|attrs|
            attrs['url'] = V1.attache_url_for(attrs['path'], geometry)
          })
        end
      end

      def attache_field_set(array, secret_key: Attache::API::V1::ATTACHE_SECRET_KEY)
        new_value = Utils.array(array).inject([]) {|sum,value|
          hash = value.respond_to?(:read) && V1.attache_upload(value) || value
          hash = JSON.parse(hash.to_s) rescue Hash(error: $!) unless hash.kind_of?(Hash)
          okay = hash.respond_to?(:[]) && (hash['path'] || hash[:path])
          if secret_key.to_s.strip != ""
            hash_without_signature = hash.reject {|k,v| k == 'signature' }
            content = hash_without_signature.sort.collect {|k,v| "#{k}=#{v}" }.join('&')
            generated_signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), secret_key, content)
            if generated_signature != hash['signature']
              okay = nil
            end
          end
          okay ? sum + [hash] : sum
        }
        Utils.array(new_value)
      end

      def attache_update_pending_diffs(old_value, new_value, pending_backup, pending_discard)
        old_paths = Utils.array(old_value).collect { |x| x['path'] }.reject { |path| path.nil? || path == "" }
        new_paths = Utils.array(new_value).collect { |x| x['path'] }.reject { |path| path.nil? || path == "" }
        pending_backup.push(*(new_paths - old_paths))
        pending_discard.push(*(old_paths - new_paths))
      end

      def attaches_discard!(files)
        files.reject! {|x| x.nil? || x == "" }
        V1.attache_delete(*files.uniq) unless files.empty?
      rescue Exception
        raise if ENV['ATTACHE_DISCARD_FAILURE_RAISE_ERROR']
      end

      def attaches_backup!(files)
        files.reject! {|x| x.nil? || x == "" }
        V1.attache_backup(*files.uniq) unless files.empty?
      end
    end
  end
end
