##################################################################
#                  Licensing Information                         #
#                                                                #
#  The following code is licensed, as standalone code, under     #
#  the Ruby License, unless otherwise directed within the code.  #
#                                                                #
#  For information on the license of this code when distributed  #
#  with and used in conjunction with the other modules in the    #
#  Amp project, please see the root-level LICENSE file.          #
#                                                                #
#  © Michael J. Edgar and Ari Brown, 2009-2010                   #
#                                                                #
##################################################################

require 'time'

module Amp
  module Rugged
    
    ##
    # A Changeset is a simple way of accessing the repository within a certain
    # revision. For example, if the user specifies revision # 36, or revision
    # 3adf21, then we can look those up, and work within the repository at the
    # moment of that revision.
    class Changeset < Amp::Core::Repositories::AbstractChangeset

      module GitShell
        def git(command)
          #p command
          %x{git --git-dir=#{repo.root}/.git --work-tree=#{repo.root} #{command} 2> /dev/null}
        end
      end
      include GitShell
      
      attr_accessor :repo
      attr_reader   :revision
      alias_method :repository, :repo
      
      def initialize(repo, short_name)
        @repo       = repo
        if short_name.kind_of?(Integer)
          @revision = short_name
          @node_id = convert_rev_to_node(short_name)
        else
          @revision = convert_node_to_rev(short_name)
          @node_id = short_name
        end
      end
      
      def node; @node_id; end
      
      
      ##
      # Compares 2 changesets so we can sort them and whatnot
      # 
      # @param [Changeset] other a changeset we will compare against
      # @return [Integer] -1, 0, or 1. Typical comparison.
      def <=>(other)
        date <=> other.date
      end
      
      ##
      # Iterates over every tracked file at this point in time.
      # 
      # @return [Changeset] self, because that's how #each works
      def each(&b)
        all_files.each( &b)
        self
      end
      
      ##
      # the nodes that this node inherits from
      # 
      # @return [Array<Abstract Changeset>]
      def parents
        parse!
        @parents
      end

      ##
      # Retrieve +filename+
      #
      # @return [AbstractVersionedFile]
      def get_file(filename)
        VersionedFile.new @repo, file, :revision => node
      end
      alias_method :[], :get_file

      ##
      # When was the changeset made?
      # 
      # @return [Time]
      def date
        parse!
        @date
      end

      ##
      # The user who made the changeset
      # 
      # @return [String] the user who made the changeset
      def user
        parse!
        @user
      end
      
      ##
      # Which branch this changeset belongs to
      # 
      # @return [String] the user who made the changeset
      def branch
        parse!
        raise NotImplementedError.new("branch() must be implemented by subclasses of AbstractChangeset.")
      end

      ##
      # @return [String]
      def description
        parse!
        @description
      end
      
      ##
      # What files have been altered in this changeset?
      # 
      # @return [Array<String>]
      def altered_files
        parse!
        @altered_files
      end
      
      ##
      # Returns a list of all files that are tracked at this current revision.
      #
      # @return [Array<String>] the files tracked at the given revision
      def all_files
        parse!
        @all_files
      end
      
      # Is this changeset a working changeset?
      #
      # @return [Boolean] is the changeset representing the working directory?
      def working?
        false
      end
      
      private
      
      
      ##
      # Converts a semi-reliable revision # into a git changeset node.
      def convert_rev_to_node(rev)
        git("rev-list --reverse HEAD").split("\n")[rev - 1]
      end
      
      ##
      # Converts a git changeset node into a semi-reliable revision #
      def convert_node_to_rev(node)
        git("rev-list --reverse HEAD 2>/dev/null | grep -n #{node} 2>/dev/null | cut -d: -f1").to_i
      end
        
      
      # yeah, i know, you could combine these all into one for a clean sweep.
      # but it's clearer this way
      def parse!
        return if @parsed
        
        parse_existing || parse_new
        
        @parsed = true
      end

      def parse_existing
        # the parents
        log_data = git("log -1 #{node}^")
        return false if log_data.empty?
        
        # DETERMINING PARENTS
        dad   = log_data[/^commit (.+)$/, 1]
        dad   = dad ? dad[0..6] : nil
        mom   = nil
        
        if log_data =~ /^Merge: (.+)\.\.\. (.+)\.\.\.$/ # Merge: 1c002dd... 35cfb2b...
          dad = $1 # just have them both use the short name, nbd
          mom = $2
        end
        
        @parents = [dad, mom].compact.map {|r| Changeset.new repo, r }
        
        # the actual changeset
        log_data = git("log -1 #{node}")
        
        # DETERMINING DATE
        if log_data.match(/Date/)
          @date = Time.parse log_data[/^Date:\s+(.+)$/, 1]
        else
          @date = Time.now
        end
        
        # DETERMINING USER
        @user = log_data[/^Author:\s+(.+)$/, 1]
        
        # DETERMINING DESCRIPTION
        lines = log_data.split("\n")[4..1]
        if (lines)
          @description = lines.map {|l| l.strip }.join "\n"
        else
          @description = ''
        end
        
        # ALTERED FILES
        @altered_files = git("log -1 --pretty=oneline --name-only #{node}").split("\n")[1..-1]

        # ALL FILES
        # @all_files is also sorted. Hooray!
        @all_files = git("ls-tree -r #{node}").split("\n").map do |line|
          # 100644 blob cdbeb2a42b714a4db49293c87fec4e180d07d44f    .autotest
          line[/^\d+ \w+ \w+\s+(.+)$/, 1]
        end
        
        return true
      end

      def parse_new
        @parents = []
        @date = Time.now
        @user = ''
        @description = ''
        @altered_files = []
        @all_files = []
        
        return true
      end
      
    end
    
    class WorkingDirectoryChangeset < Amp::Core::Repositories::AbstractChangeset

      include Changeset::GitShell
      
      attr_accessor :repo
      alias_method :repository, :repo
      
      def initialize(repo, opts={:text => ''})
        @repo = repo
        @text = opts[:text]
        @date = opts[:date] ? Time.parser(opts[:date].to_s) : Time.now
        @user = opts[:user]
        @parents = opts[:parents].map {|p| Changeset.new(@repo, p) } if opts[:parents]
        @status  = opts[:changes]
      end
      
      ##
      # the nodes that this node inherits from
      # 
      # @return [Array<Abstract Changeset>]
      def parents
        @parents || (parse! && @parents)
      end
      
      def revision; nil; end

      ##
      # Retrieve +filename+
      #
      # @return [AbstractVersionedFile]
      def get_file(filename)
        VersionedWorkingFile.new @repo, filename
      end
      alias_method :[], :get_file

      ##
      # When was the changeset made?
      # 
      # @return [Time]
      def date
        Time.now
      end

      ##
      # The user who made the changeset
      # 
      # @return [String] the user who made the changeset
      def user
        @user ||= @repo.config.username
      end
      
      ##
      # Which branch this changeset belongs to
      # 
      # @return [String] the user who made the changeset
      def branch
        @branch ||= git("branch")[/\*\s(.+)$/, 1]
      end

      ##
      # @return [String]
      def description
        @text || ''
      end
      
      def status
        @status ||= @repo.status :unknown => true
      end
      
      ##
      # Iterates over every tracked file at this point in time.
      # 
      # @return [Changeset] self, because that's how #each works
      def each(&b)
        all_files.each( &b)
        self
      end
      
      ##
      # Returns a list of all files that are tracked at this current revision.
      #
      # @return [Array<String>] the files tracked at the given revision
      def all_files
        @all_files ||= git("ls-files").split("\n")
      end
      
      # Is this changeset a working changeset?
      #
      # @return [Boolean] is the changeset representing the working directory?
      def working?
        true
      end
      
      ##
      # Recursively walk the directory tree, getting all files that +match+ says
      # are good.
      # 
      # @param [Amp::Match] match how to select the files in the tree
      # @param [Boolean] check_ignored (false) should we check for ignored files?
      # @return [Array<String>] an array of filenames in the tree that match +match+
      def walk(match, check_ignored = false)
        tree = @repo.staging_area.walk true, check_ignored, match
        tree.keys.compact.sort
      end
      
      # What files have been altered in this changeset?
      def altered_files; git("show --name-only #{node}").split("\n"); end
      # What files have changed?
      def modified; status[:modified]; end
      # What files have we added?
      def added; status[:added]; end
      # What files have been removed?
      def removed; status[:removed]; end
      # What files have been deleted (but not officially)?
      def deleted; status[:deleted]; end
      # What files are hanging out, but untracked?
      def unknown; status[:unknown]; end
      # What files are pristine since the last revision?
      def clean; status[:normal]; end
      
      # yeah, i know, you could combine these all into one for a clean sweep.
      # but it's clearer this way
      def parse!
        return if @parsed
        
        log_data = git("log -1 HEAD")
        
        unless log_data.empty?
          # DETERMINING PARENTS
          commit = log_data[/^commit (.+)$/, 1]
          dad    = commit ? commit[0..6] : nil
          mom    = nil
          
          if log_data =~ /^Merge: (.+)\.\.\. (.+)\.\.\.$/ # Merge: 1c002dd... 35cfb2b...
            dad = $1 # just have them both use the short name, nbd
            mom = $2
          end
          
          @parents = [dad, mom].compact.map {|p| Changeset.new @repo, p }
        else
          @parents = []
        end
        @parsed = true
      end
      
    end
  end
end
