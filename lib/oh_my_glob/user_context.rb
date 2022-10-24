# encoding: utf-8

require 'etc'

module OhMyGlob
  ##
  # The `UserContext` uses the _UNSECURE_ Etc utility to report
  # the process's user context including readable username and
  # available group membership.
  #
  # Because the underlying information is easily spoofed, this
  # utlity is ONLY meant to provide hints about the context and
  # MUST NOT be relied upon for security access.
  class UserContext

    def self.get
      @@instance ||= new
    end

    attr_reader :username
    attr_reader :groups

    def initialize
      @username = Etc.getlogin.dup.freeze rescue nil
      @groups = load_groups(@username) || nil
    end

    def to_s
      return 'UNKNOWN' if username.nil? && groups.nil?
      return username if groups.nil?

      "#{username}:(#{groups.join(',')})"
    end

    private

    def load_groups(username)
      return nil unless username

      groups = []
      Etc.group { |g| groups << g.name if g.mem.include?(@username) }

      groups.map(&:dup).map(&:freeze).freeze
    end
  end
end