# frozen_string_literal: true

module ParseFullName
  module Helpers
    def blank?(obj)
      obj.respond_to?(:empty?) ? obj.empty? : obj.nil?
    end

    def present?(obj)
      !blank(obj)
    end
  end
end
