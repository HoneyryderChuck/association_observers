# -*- encoding : utf-8 -*-
module AssociationObservers
  module Backports
    def self.extended_to_s(val)
      if val.is_a?(Hash)
        "{#{val.map{|k, v| ":#{k}=>#{extended_to_s(v)}"}.join(",")}}"
      elsif val.is_a?(Array)
        "[#{val.map{|a|extended_to_s(a)}.join(",")}]"
      else
        val.is_a?(Symbol) ? ":#{val}" : val.is_a?(String) ? "\"#{val}\"" : val
      end
    end


    def self.hash_select(hash, &proc)
      Hash[hash.select(&proc)]
    end

    module Proc
      # it's called fake curry because it only works on one level, that is, you can only pass one level of sub-arguments
      # sorry, ruby 1.8 sucks balls
      def self.fake_curry(method, *args)
        proc { |*proc_args|
          method.call(*(args + proc_args))
        }
      end
    end

  end
end
