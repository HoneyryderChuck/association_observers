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
      def self.curry(method, argc = nil)
        min_argc = method.arity < 0 ? -method.arity - 1 : method.arity
        argc ||= min_argc
        block = proc do |*args|
          if args.size >= argc
            method.call(*args)
          else
            proc do |*more_args|
              args += more_args
              block.call(*args)
            end
          end
        end
      end
    end

  end
end
