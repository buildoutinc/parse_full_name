# frozen_string_literal: true

module ParseFullName
  class Name
    ATTRIBUTES = %i[first_name middle_name last_name title suffix nickname].freeze
    attr_accessor(*ATTRIBUTES)

    def initialize(first_name: "", middle_name: "", last_name: "", title: "", suffix: "", nickname: "")
      @first_name = first_name
      @middle_name = middle_name
      @last_name = last_name
      @title = title
      @suffix = suffix
      @nickname = nickname
    end

    def dup
      self.class.new(to_h)
    end

    def to_h
      ATTRIBUTES.each_with_object({}) do |attribute, h|
        h[attribute] = self.send(attribute)
      end
    end

    # Transforms a name using the provided block.
    #
    # @example Upcasing a name except for the nickname
    #   name = Name.new(
    #     first_name: "Pete",
    #     last_name: "Mitchell",
    #     nickname: "Maverick"
    #   )
    #   new_name = name.transform do |attribute, value|
    #     attribute == :nickname ? value : value.upcase
    #   end
    #
    #   new_name.first_name #=> "PETE"
    #   new_name.last_name #=> "MITCHELL"
    #   new_name.nickname #=> "Maverick"
    #
    # @yieldparam attribute [Symbol] key of the name part being provided
    # @yieldparam value [String] value of the name part being provided
    # @yieldreturn new_value [String] new value for the name part
    # @return [ParseFullName::Name] new name with the transformed values
    def transform
      ATTRIBUTES.each_with_object(self.class.new) do |attribute, name|
        value = yield attribute, send(attribute).dup
        name.send("#{attribute}=", value)
      end
    end
  end
end
