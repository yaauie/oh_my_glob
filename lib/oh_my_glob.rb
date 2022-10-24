require "oh_my_glob/version"

require_relative 'oh_my_glob/trouble_detector'

module OhMyGlob
  class Error < StandardError; end

  def detect_trouble(glob_pattern, glob_flags=[])
    TroubleDetector.detect_trouble(glob_pattern, glob_flags)
  end
  module_function :detect_trouble

  ##
  # A drop-in replacement for Dir#glob that _always_ detects trouble after
  # completing the file listing, and reports trouble to $stderr.
  #
  # @param glob_pattern [String]
  # @param glob_flags [Integer]
  #
  # @overload each_file(glob_pattern [, glob_flags])

  def each_file(glob_pattern, glob_flags=0, *args, &block)
    return enum_for :each_file, glob_pattern, glob_flags unless block_given?

    Globber.new(glob_pattern, glob_flags, report: 'ALWAYS', *args).each_file do |file|
      yield file
    end
  end
  ruby2_keywords :each_file if respond_to?(:ruby2_keywords)
  module_function :each_file
end
