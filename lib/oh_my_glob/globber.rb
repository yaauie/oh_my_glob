# encoding: utf-8

require_relative 'glob_flags_util'
require_relative 'report_trigger'
require_relative 'reporter'
require_relative 'user_context'

module OhMyGlob
  class Globber
    def initialize(glob_pattern, glob_flags=0, logger: $stderr, report: :first_run, **glob_options)
      @glob_pattern = glob_pattern.dup.freeze
      @glob_flags = GlobFlagsUtil::glob_flags(glob_flags)
      @glob_base = glob_options[:base]
      @glob_options = glob_options

      @logger = load_logger(logger)
      @report_trigger = ReportTrigger.construct(report)
    end

    ##
    # ~~~
    # globber = OhMyGlob::Globber.new(pattern, flags)
    # globber.each_file { |filename| ... }
    # ~~~
    #
    # ~~~ ruby
    # Dir.glob(pattern, flags) { |filename| ... }
    # ~~~
    #
    def each_file(on_trouble: :noop)
      return enum_for :each unless block_given?

      reporter = new_reporter
      @report_trigger.observe(reporter) do |observation|
        Dir.glob(@glob_pattern, @glob_flags, **@glob_options).each do |match|
          observation.record_match(match)
          yield(match)
        end
      end

      if reporter.trouble_detected?
        case on_trouble
        when :noop   then :noop
        when :exit   then exit(17)
        when :raise  then raise(Error, "trouble detected with `#{@glob_pattern}` using flags `#{GlobFlagsUtil.names(@glob_flags)}`")
        end
      end

      nil
    end

    private

    def new_reporter
      Reporter.new(glob_pattern: @glob_pattern, glob_flags: @glob_flags, glob_base: @glob_base, logger: @logger)
    end

    def load_logger(loggerlike)
      case loggerlike
      when :warn_only then IOLogger.new($stderr, nil)
      when IO         then IOLogger.new(loggerlike, loggerlike)
      else
        %w(warn error debug).each do |mthd|
          fail(ArgumentError, "provided logger MUST respond to #{mthd}") unless loggerlike.respond_to?(mthd)
        end

        loggerlike
      end
    end
  end

  class IOLogger
    def initialize(warn_io, info_io)
      @warn_io = warn_io
      @info_io = info_io
    end
    def warn(message, context=nil)
      @warn_io&.puts("WARN: #{message}#{context && ' '}#{context&.inspect}\n")
    end
    def info(message, context=nil)
      @info_io&.puts("INFO: #{message}#{context && ' '}#{context&.inspect}\n")
    end
  end
end