# frozen_string_literal: true

require "set"
require_relative "helpers"
require_relative "name"

module ParseFullName
  class Parser
    include Helpers

    FIX_CASE_MODES = %i[always never smart].freeze
    NICKNAME_REGEX = /\s(?:[‘’'](?:[^‘’']+)[‘’']|[“”"](?:[^“”"]+)[“”"]|\[(?:[^\]]+)\]|\((?:[^)]+)\)),?\s/

    def initialize(name, fix_case_mode: :smart, use_long_lists: false, config: Configuration.new)
      raise ArgumentError, "Name is required" if blank?(name)
      raise ArgumentError, "Invalid fix_case_mode" unless FIX_CASE_MODES.include?(fix_case_mode)

      @name = name
      @fix_case_mode = fix_case_mode

      list = use_long_lists ? :long : :short
      @conjunctions = config.conjunctions
      @force_case_words = config.force_case_words
      @prefixes = config.prefixes(list)
      @suffixes = config.suffixes(list)
      @titles = config.titles(list)

      @name_parts = []
      @name_commas = [nil]
      @remaining_commas = nil
    end

    def to_name
      parsed_name = Name.new

      parsed_name.nickname = identify_nickname
      return fix_case(parsed_name) if blank?(@name.strip)

      split_name_with_commas

      parsed_name.suffix = identify_affixes(type: :suffix)
      return fix_case(parsed_name) if @name_parts.empty?

      parsed_name.title = identify_affixes(type: :title)
      return fix_case(parsed_name) if @name_parts.empty?

      join_prefixes
      join_conjunctions

      parsed_name.suffix = [parsed_name.suffix, identify_extra_suffixes]
                             .reject { |s| blank?(s) }
                             .join(", ")

      parsed_name.last_name = identify_last_name
      return fix_case(parsed_name) if @name_parts.empty?

      parsed_name.first_name = @name_parts.shift
      return fix_case(parsed_name) if @name_parts.empty?

      parsed_name.middle_name = @name_parts.join(" ")

      fix_case(parsed_name)
    end

    def to_h
      to_name.to_h
    end

    private

    def identify_last_name
      if @remaining_commas.zero?
        @name_parts.pop
      elsif @name_commas.include?(",")
        comma_index = @name_commas.index(",")
        last_name = @name_parts.slice!(0, comma_index).join(" ")
        @name_commas.slice!(0, comma_index)

        last_name
      end
    end

    def identify_nickname
      matches = " #{@name} ".scan(NICKNAME_REGEX)
      nicknames = []

      matches.each do |match|
        nicknames << match[2...-2].gsub(/,\Z/, "")
        @name = " #{@name} ".gsub(match, " ").strip
      end

      nicknames.join(", ")
    end

    def identify_affixes(type:)
      affixes_found = []
      name_part_size = @name_parts.length

      case type
      when :title
        start_index = 0
        predefined_list = @titles
      when :suffix
        start_index = 1
        predefined_list = @suffixes
      else
        raise ArgumentError, "Invalid type"
      end

      (start_index...name_part_size).reverse_each do |i|
        part = @name_parts[i]
        part = part[-1] == "." ? part[0...-1].downcase : part.downcase

        if predefined_list.include?(part) || predefined_list.include?("#{part}.")
          affixes_found.prepend(@name_parts.delete_at(i))
          if @name_commas[i] == "," # keep comma
            @name_commas.slice!(i + 1, 1)
          else
            @name_commas.slice!(i, 1)
          end
        end
      end

      affixes_found.join(", ")
    end

    def identify_extra_suffixes
      suffixes_found = []
      @name_commas.pop
      first_comma_index = @name_commas.index(",")
      @remaining_commas = @name_commas.compact.length

      if (first_comma_index && first_comma_index > 1) || @remaining_commas > 1
        (2...@name_parts.length).reverse_each do |i|
          break unless @name_commas[i] == ","

          suffixes_found.prepend(@name_parts.delete_at(i))
          @name_commas.delete_at(i)
          @remaining_commas -= 1
        end
      end

      suffixes_found.join(", ")
    end

    def fix_case(parsed_name)
      return parsed_name unless fix_case?

      parsed_name.transform do |attribute, value|
        name_in_words = value.split(" ").map do |word|
          predefined_case = @force_case_words.detect { |force_word| word.downcase == force_word.downcase }
          next predefined_case if predefined_case # use capitalization from predefined list
          next word.upcase if word.length == 1 # upcase initials
          next word[0..2] + word[3..-1].downcase if convert_mc_case?(word) # convert McCASE to McCase

          if attribute == :suffix && word[-1] != "." && !@suffixes.include?(word.downcase)
            word == word.downcase ? word.upcase : word # upcase suffix if all lower case
          else
            word[0].upcase + word[1..-1].downcase # title case everything else
          end
        end

        name_in_words.join(" ")
      end
    end

    def fix_case?
      @fix_case ||= case @fix_case_mode
                    when :smart
                      @name == @name.upcase || @name == @name.downcase
                    when :always
                      true
                    else
                      false
                    end
    end

    def join_prefixes
      return unless @name_parts.length > 1

      (0...(@name_parts.length - 1)).reverse_each do |i|
        next unless @prefixes.include?(@name_parts[i].downcase)

        @name_parts[i] = "#{@name_parts[i]} #{@name_parts[i + 1]}"
        @name_parts.delete_at(i + 1)
        @name_commas.delete_at(i + 1)
      end
    end

    def join_conjunctions
      return [@name_parts, @name_commas] unless @name_parts.length > 2

      i = @name_parts.length - 3

      while i >= 0
        if @conjunctions.include?(@name_parts[i + 1].downcase)
          @name_parts[i] = @name_parts[i..(i + 2)].join(" ")
          @name_parts.slice!((i + 1)..(i + 2))
          @name_commas.slice!((i + 1)..(i + 2))
          i -= 1 # skip one word
        end

        i -= 1
      end
    end

    def split_name_with_commas
      @name.split(" ").each do |part|
        comma = nil
        if part[-1] == ","
          comma = ","
          part = part[0..-2]
        end

        @name_parts << part
        @name_commas << comma
      end
    end

    # Should convert McCASE to McCase
    def convert_mc_case?(word)
      word.length > 2 &&
        word[0] == word[0].upcase &&
        word[1] == word[1].downcase &&
        word[2..-1] == word[2..-1].upcase
    end
  end
end
