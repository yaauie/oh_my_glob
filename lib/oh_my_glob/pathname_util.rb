# encoding: utf-8

module OhMyGlob
  module PathnameUtil

    GLOBPATTERN = Regexp.union('*','?','[',']','{','}')

    def find_glob_root(pathname)
      return find_root(pathname) do |candidate_root|
        next false if GLOBPATTERN.match?(candidate_root.to_s)
        next false unless candidate_root.exist?

        true
      end
    end
    module_function :find_glob_root

    def find_root(pathname, &descend_child_condition)
      root, remaining = nudge(pathname.expand_path.cleanpath)

      if block_given?
        loop do
          candidate_root, candidate_remaining = shift(root, remaining)

          break if candidate_root + candidate_remaining == candidate_root # end-of-path

          should_descend = yield(candidate_root)

          break unless yield(candidate_root)
          root, remaining = candidate_root, candidate_remaining
        end
      end

      return root, remaining
    end
    module_function :find_root

    def shift(lhs, rhs)
      mid, new_rhs = nudge(rhs)

      [lhs + mid, new_rhs]
    end
    module_function :shift

    def recursive_globish?(pathname)
      pathname.to_s.include?('**')
    end
    module_function :recursive_globish?

    def nudge(pathname)
      lhs = pathname.descend.first
      rhs = pathname.relative_path_from(lhs)

      [lhs,rhs]
    end
    module_function :nudge
  end
end