# encoding: utf-8

module OhMyGlob
  class Trouble
    attr_reader :path
    attr_reader :globmatch
    attr_reader :globremain

    def initialize(path, globmatch, globremain)
      @path = path
      @globmatch = globmatch
      @globremain = globremain
    end

    def ownership_summary
      stat = @path.stat

      user = Etc.getpwuid(stat.uid).name rescue nil
      group = Etc.getgrgid(stat.gid).name rescue nil
      mode = stat.mode

      "#{mode&.to_s(8) || 'unknown'} #{user || stat.uid}:#{group || stat.gid}"
    end

    def report
      "failed to list the contents of `#{path}` whose permissions are `#{ownership_summary}`; " +
      "this directory matches the partial glob `#{globmatch}`, and files matching the remaining glob `#{globremain}` may be missing from discovery"
    end

  end
end