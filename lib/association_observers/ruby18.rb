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
  end
end