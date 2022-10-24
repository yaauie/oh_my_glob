# encoding: utf-8

module OhMyGlob
  module ReportTrigger # "interface"
    def observe(reporter, &observable)
      fail NotImplementedError
    end

    ##
    # @param other [ReportTrigger]
    # @return [ReportTrigger]
    def combine(other)
      return CombinedReportTrigger.new(self, other)
    end

    module Observation # "interface"
      def record_match(match_data)
        # no-op
      end

      def report(force: false, &do_report)
        fail NotImplementedError
      end
    end

    def self.construct(named_conditions)
      Array(named_conditions).map do |named_condition|
        case named_condition.to_s.upcase
        when 'PREFLIGHT'      then PreFlightReportTrigger.new
        when 'FIRST_RUN'      then FirstExecutionReportTrigger.new
        when 'ON_EMPTY'       then EmptyResultReportTrigger.new
        when 'ALWAYS'         then AlwaysReportTrigger.new
        when /STALE\((\d+)\)/ then StaleReportTrigger.new(Regexp::last_match(1).to_i)
        else fail ArgumentError, "Unsupported ReportTrigger: #{named_condition}"
        end
      end.reduce(&:combine)
    end

    class FirstExecutionReportTrigger
      include ReportTrigger # implements "interface"
      include Observation # implements "interface"

      def initialize
        @first_run = true
      end

      def observe(reporter, &observable)
        yield(self)

        is_first, @first_run = @first_run, false
        reporter.trigger if is_first
      end

      def record_match(match_data)
        # no-op
      end
    end

    class AlwaysReportTrigger
      include ReportTrigger # implements "interface"
      include Observation # implements "interface"

      def observe(reporter, &observable)
        yield self

        reporter.trigger
      end

      def record_match(match_data)
        # no-op
      end
    end

    class PreFlightReportTrigger
      include ReportTrigger # implements "interface"
      include Observation # implements "interface"

      def observe(reporter, &observable)
        yield self unless reporter.trigger
      end

      def record_match(match_data)
        # no-op
      end
    end

    class StaleReportTrigger
      include ReportTrigger # implements "interface"
      include Observation # implements "interface"

      def initialize(staleness_threshold_in_seconds)
        @staleness_threshold_in_seconds = staleness_threshold_in_seconds
        @last_fresh = Time.now
      end

      def observe(reporter, &observable)
        yield self

        reporter.trigger if (@last_fresh + @staleness_threshold_in_seconds < Time.now)
      end

      def record_match(match_data)
        @last_fresh = Time.now
      end
    end

    class EmptyResultReportTrigger
      include ReportTrigger # implements "interface"

      def observe(reporter, &observable)
        observation = EmptyResultObservation.new
        yield observation

        reporter.trigger unless results_seen?
      end

      class EmptyResultObservation
        include Observation # implements "interface"

        def initialize
          @results_seen = false
        end

        def record_match(match_data)
          @results_seen = true
        end

        def results_seen?
          @results_seen
        end
      end
    end

    class CombinedReportTrigger
      include ReportTrigger # implements "interface"

      def initialize(lhs,rhs)
        @lhs, @rhs = lhs, rhs
      end

      def observe(reporter, &observable)
        @lhs.observe(reporter) do |_lhs|
          @rhs.observe(reporter) do |_rhs|
            yield(CombinedObservation.new(_lhs, _rhs))
          end
        end
      end

      class CombinedObservation
        include Observation # implements "interface"

        def initialize(lhs,rhs)
          @lhs, @rhs = lhs, rhs
        end

        def record_match(match_data)
          @lhs.record_match(match_data)
          @rhs.record_match(match_data)
        end
      end
    end
  end
end