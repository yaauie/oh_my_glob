# encoding: utf-8

require_relative 'trouble_detector'

module OhMyGlob
  class Reporter
    def initialize(glob_pattern:, glob_flags:, glob_base:, logger:)
      @glob_pattern = Pathname.new(glob_pattern).expand_path(glob_base)
      @glob_flags = glob_flags
      @logger = logger

      @trouble_detected = nil
    end

    def trigger
      if @trouble_detected.nil?

        troubles = TroubleDetector::detect_trouble(@glob_pattern, @glob_flags)

        if troubles.any?
          @logger.warn("the provided glob pattern may be unable to discover one or more files",
                        pattern: @glob_pattern, flags: GlobFlagsUtil.names(@glob_flags), user: UserContext.get.to_s)
          troubles.each do |trouble|
            @logger.warn(trouble.report)
          end
          @trouble_detected = true
        else
          @logger.info("no issues detected with provided glob pattern",
                        pattern: @glob_pattern, flags: GlobFlagsUtil.names(@glob_flags), user: UserContext.get.to_s)
          @trouble_detected = false
        end
      end

      return @trouble_detected
    end

    def was_triggered?
      !@trouble_detected.nil?
    end

    def trouble_detected?
      @trouble_detected
    end
  end
end