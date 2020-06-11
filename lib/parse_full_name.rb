require "parse_full_name/version"
require "parse_full_name/configuration"
require "parse_full_name/parser"

module ParseFullName
  # Parses a full name in a variety of formats
  #
  # @param name [String] name to be parsed
  # @param fix_case_mode [Symbol] `:always`, `:never`, or `:smart`
  # @param use_long_lists [Boolean] use the longer lists for prefixes, suffixes, and titles
  # @param config [ParseFullName::Configuration] configuration for all word lists
  # @return [Hash] name parsed into
  def self.parse(name, fix_case_mode: :smart, use_long_lists: false, config: Configuration.new)
    Parser.new(name, fix_case_mode: fix_case_mode, use_long_lists: use_long_lists, config: config).to_name
  end
end
