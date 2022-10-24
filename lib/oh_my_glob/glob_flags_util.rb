# encoding: utf-8

module OhMyGlob
  module GlobFlagsUtil
    def glob_flags(flags)
      return flags if flags.kind_of?(Integer)

      Array(flags).map { |flag| glob_flag(flag) }.reduce(0,:|)
    end
    module_function :glob_flags

    def glob_flag(input)
      return input if input.kind_of?(Integer)
      return Integer(input) if input =~ /\A[0-9]+\Z/

      case (input.to_s.upcase rescue nil)
      when 'CASEFOLD'  then File::FNM_CASEFOLD
      when 'DOTMATCH'  then File::FNM_DOTMATCH
      when 'EXTGLOB'   then File::FNM_EXTGLOB
      when 'NOESCAPE'  then File::FNM_NOESCAPE
      when 'PATHNAME'  then File::FNM_PATHNAME
      when 'SHORTNAME' then File::FNM_SHORTNAME
      else
        raise ArgumentError, "Unsupported FNM flag: `#{input}`"
      end
    end
    module_function :glob_flag

    FLAG_MAP = %w(
      CASEFOLD
      DOTMATCH
      EXTGLOB
      NOESCAPE
      PATHNAME
      SHORTNAME
    ).each_with_object({}) do |name, memo|
      memo[glob_flag(name)] = name
    end

    def names(glob_flags)
      remaining = glob_flags
      named_flags = FLAG_MAP.each_with_object([]) do |(flag, name), memo|
        if !(remaining & flag).zero?
          remaining = remaining ^ flag
          memo << name
        end
      end
      named_flags << "<UNKNOWN:#{remaining.to_s(2)}>" unless remaining.zero?
      return named_flags.any? ? named_flags.join(',') : "<NONE>"
    end
    module_function :names
  end
end