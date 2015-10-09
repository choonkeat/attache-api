module Attache
  module API
    module Utils
      class << self
        def array(value)
          case value
          when Array
            value
          else
            [value]
          end.reject {|x| x.nil? || x == "" }
        end
      end
    end
  end
end
