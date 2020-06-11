# frozen_string_literal: true

require "set"
require "yaml"

module ParseFullName
  class Configuration
    DEFAULT_CONFIG_FILE_PATH = File.expand_path("../../config.yml", File.dirname(__FILE__))

    def initialize(file_path = DEFAULT_CONFIG_FILE_PATH)
      @config = YAML.load_file(file_path)
    end

    # Provides a list of known conjunctions
    #
    # @return [Set] list of conjunctions
    def conjunctions
      Set.new(@config[:conjunctions] || []).freeze
    end

    # Provides a list of words that need to have their case forced
    #
    # @return [Set] list of words to have their case forced
    def force_case_words
      Set.new(@config[:force_case] || []).freeze
    end

    # Provides a list of known name prefixes
    #
    # @param list [Symbol] the list type, `:short` or `:long`
    # @return [Set] list of known prefixes
    def prefixes(list = :short)
      Set.new(@config.dig(:prefixes, list) || []).freeze
    end

    # Provides a list of known name suffixes
    #
    # @param list [Symbol] the list type, `:short` or `:long`
    # @return [Set] list of known suffixes
    def suffixes(list = :short)
      Set.new(@config.dig(:suffixes, list) || []).freeze
    end

    # Provides a list of known name titles
    #
    # @param list [Symbol] the list type, `:short` or `:long`
    # @return [Set] list of known titles
    def titles(list = :short)
      Set.new(@config.dig(:titles, list) || []).freeze
    end
  end
end
