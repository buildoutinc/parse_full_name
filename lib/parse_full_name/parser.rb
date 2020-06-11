# frozen_string_literal: true

require "set"

module ParseFullName
  class Parser
    FIX_CASE_MODES = %i[always never smart].freeze
    NICKNAME_REGEX = /\s(?:[‘’'](?:[^‘’']+)[‘’']|[“”"](?:[^“”"]+)[“”"]|\[(?:[^\]]+)\]|\((?:[^)]+)\)),?\s/

    def initialize(name, fix_case_mode: :smart, use_long_lists: false, config: Configuration.new)
      raise ArgumentError, "Name is required" if name.nil? || name == ""
      raise ArgumentError, "Invalid fix_case_mode" unless FIX_CASE_MODES.include?(fix_case_mode)

      @name = name
      @fix_case_mode = fix_case_mode

      list = use_long_lists ? :long : :short
      @conjunctions = config.conjunctions
      @force_case_words = config.force_case_words
      @prefixes = config.prefixes(list)
      @suffixes = config.suffixes(list)
      @titles = config.titles(list)
    end

    def to_name
      name = @name
      parsed_name = Name.new

      # Parse nickname
      result = find_and_remove_nickname(name)
      name = result[:modified_name]
      parsed_name.nickname = result[:nickname]
      return fix_case(parsed_name) if name.strip.blank?

      # Split rest of name
      name_parts, name_commas = split_name_with_commas(name)

      # Parse suffixes
      result = find_and_remove_affixes(name_parts, name_commas, type: :suffix)
      parsed_name.suffix = result[:name_part]
      name_parts = result[:name_parts]
      name_commas = result[:name_commas]
      return fix_case(parsed_name) if name_parts.empty?

      # Parse titles
      result = find_and_remove_affixes(name_parts, name_commas, type: :title)
      parsed_name.title = result[:name_part]
      name_parts = result[:name_parts]
      name_commas = result[:name_commas]
      return fix_case(parsed_name) if name_parts.empty?

      # Join prefixes & conjunctions
      name_parts, name_commas = join_prefixes(name_parts, name_commas)
      name_parts, name_commas = join_conjunctions(name_parts, name_commas)

      # Join conjunctions
      # Extra suffixes
      # Last name
      # First name
      # Middle name

      parsed_name
    end

    def to_h
      to_name.to_h
    end

    # Parses a full name in a variety of formats
    #
    # @param name [String] name to be parsed
    # @param fix_case_mode [Symbol] `:always`, `:never`, or `:smart`
    # @param use_long_lists [Boolean] use the longer lists for prefixes, suffixes, and titles
    # @param config [ParseFullName::Configuration] configuration for all word lists
    # @return [Hash] name parsed into
    def self.parse(name, fix_case_mode: :smart, use_long_lists: false, config: Configuration.new)
      new(name, fix_case_mode: fix_case_mode, use_long_lists: use_long_lists, config: config).to_h
    end

    private

    def find_and_remove_nickname(name)
      matches = " #{name} ".scan(NICKNAME_REGEX)
      nicknames = []

      matches.each do |match|
        nicknames << match[2...-2].gsub(/,\Z/, "")
        name = name.gsub(match, " ").strip
      end

      {
        nickname: nicknames.join(", "),
        modified_name: name
      }
    end

    def find_and_remove_affixes(name_parts, name_commas, type:)
      affixes_found = []
      name_parts = name_parts.dup
      name_commas = name_commas.dup
      name_part_size = name_parts.length

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

      (start_index..name_part_size).reverse_each do |i|
        part = name_parts[i]
        part = part[-1] == "." ? part[0...-1].downcase : part.downcase

        if predefined_list.include?(part) || predefined_list.include?("#{part}.")
          affixes_found.prepend(name_parts.delete_at(i))
          if name_commas[i] == "," # keep comma
            name_commas = name_commas.slice(i + 1, 1)
          else
            name_commas = name_commas.slice(i, 1)
          end
        end
      end

      {
        name_part: affixes_found.join(", "),
        modified_name_parts: name_parts,
        modified_name_commas: name_commas
      }
    end

    def find_and_remove_extra_suffixes(name_parts, name_commas)
      suffixes_found = []
      name_commas = name_commas[0..-2]
      first_comma_index = name_commas.index(",")
      remaining_commas = name_commas.compact.length

      if first_comma_index > 1 || remaining_commas > 1
        (2...name_parts.length).reverse_each do |i|
          break unless name_commas[i] == ","

          suffixes.prepend(name_parts.delete_at(i))
          name_commas.delete_at(i)
          remaining_commas -= 1
        end
      end

      {
        suffix: suffixes_found.join(", "),
        name_parts: name_parts,
        name_commas: name_commas
      }
    end

    def fix_case(parsed_name)
      return parsed_name unless fix_case?

      parsed_name.transform do |attribute, value|
        name_in_words = value.split(" ").map do |word|
          predefined_case = @force_case_words.detect { |word| word.downcase == word.downcase }
          return predefined_case if predefined_case # use capitalization from predefined list
          return word.upcase if word.length == 1 # upcase initials
          return word[0..2] + word[3..-1].downcase if convert_mc_case?(word) # convert McCASE to McCase

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
                      name == name.upcase || name == name.downcase
                    when :always
                      true
                    else
                      false
                    end
    end

    def join_prefixes(name_parts, name_commas)
      return [name_parts, name_commas] unless name_parts.length > 1

      name_parts = name_parts.dup
      name_commas = name_commas.dup

      (0...(name_parts.length - 1)).reverse_each do |i|
        next unless @prefixes.include?(name_parts[i].downcase)

        name_parts[i] = "#{name_parts[i]} #{name_parts[i + 1]}"
        name_parts.delete_at(i + 1)
        name_commas.delete_at(i + 1)
      end

      [name_parts, name_commas]
    end

    def join_conjunctions(name_parts, name_commas)
      return [name_parts, name_commas] unless name_parts.length > 2

      name_parts = name_parts.dup
      name_commas = name_commas.dup
      i = name_parts.length - 3

      while i >= 0
        if @conjunctions.include?(name_parts[i + 1].downcase)
          name_parts[i] = name_parts[i..(i + 2)].join(" ")
          name_parts.slice!((i + 1)..(i + 2))
          name_commas.slice!((i + 1)..(i + 2))
          i -= 1 # skip one word
        end

        i -= 1
      end

      [name_parts, name_commas]
    end

    def split_name_with_commas(name)
      name_parts = []
      name_commas = []

      name.split(" ").each do |part|
        comma = nil
        if part[-1] == ","
          comma = ","
          part = part[0...-1]
        end

        name_parts << part
        name_commas << comma
      end

      [name_parts, name_commas]
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
