# encoding: utf-8

require 'set'
require 'pathname'
require 'etc'

require_relative 'pathname_util'
require_relative 'glob_flags_util'
require_relative 'trouble'

module OhMyGlob
  ##
  # This `TroubleDetector` detects trouble with a given glob pattern that
  # may result in fewer matches than expected, and provides an array of
  # identified trouble-points.
  #
  # The most common issue is for one or more of the ancestor paths to not
  # be listable by the currently-active user, which will cause its contents
  # to silently not be returned by `Dir.glob` or `Pathname#glob` since the
  # user cannot see them.
  #
  # This utility uses many slower APIs to crawl the filesystem for matches,
  # reporting matching intermediates that cannot be listed and whose contents
  # would not be included in a call to the much-faster `Dir::glob`.
  module TroubleDetector

    def detect_trouble(glob_pattern, glob_flags=[])
      glob_pattern = Pathname.new(glob_pattern).cleanpath.expand_path.freeze
      glob_flags = GlobFlagsUtil.glob_flags(glob_flags)

	    root, remaining = PathnameUtil::find_glob_root(glob_pattern)

	    queue = []
	    queue << [root, root, remaining]

	    cannot_list = Hash.new

	    while (node, glob_matched, glob_remaining = queue.shift)
	      # next if cannot_list.include?(node)
	      begin
	        next unless node.directory?

	        child_glob, child_glob_remaining = PathnameUtil::shift(node, glob_remaining)

	        node.children.each do |child|
	          next if (child_glob + child_glob_remaining == child_glob)
	          next unless child.fnmatch?(child_glob.to_s, glob_flags)

	          child_glob_matched = PathnameUtil::recursive_globish?(glob_matched) ? glob_matched : (glob_matched + child_glob.basename)

	          queue << [child, child_glob_matched, child_glob_remaining]
            queue << [child, child_glob_matched, glob_remaining] if PathnameUtil::recursive_globish?(child_glob.basename)
	        end
	      rescue Errno::EACCES
	        cannot_list[node]= Trouble.new(node, glob_matched, glob_remaining)
	      end
	    end

      return cannot_list.values
	  end
    module_function :detect_trouble

	end
end