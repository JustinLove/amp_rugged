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

module Amp
  module Core
    module Repositories    
      module Rugged
        
        class LocalRepository < Amp::Core::Repositories::AbstractLocalRepository
          def git(command)
            #p command
            %x{git --git-dir=#{root}/.git --work-tree=#{root} #{command} 2> /dev/null}
          end
          
          attr_accessor :root
          attr_accessor :config
          attr_accessor :file_opener
          attr_accessor :git_opener
          attr_accessor :staging_area
          
          def initialize(path="", create=false, config=nil)
            super(path, create, config)
            
            @config = config
            
            @file_opener = Support::RootedOpener.new @root # This will open relative to the repo root
            @file_opener.default = :open_file    # these two are the same, pretty much
            @git_opener  = Support::RootedOpener.new @root # this will open relative to root/.git
            @git_opener.default  = :open_git     # just with different defaults
            
            @staging_area = Amp::Core::Repositories::Rugged::StagingArea.new self
            
            if create
              init
            end
          end
          
          def init(config=@config)
            super(config)
            
            git('init')
            true
          end
          
          ##
          # Regarding branch support.
          #
          # For each repository format, you begin in a default branch.  Each repo format, of
          # course, starts with a different default branch.  Git's is "master".
          #
          # @api
          # @return [String] the default branch name
          def default_branch_name
            "master"
          end
          
          def commit(opts={})
            add_all_files
            string = "commit #{opts[:user] ? "--author #{opts[:user].inspect}" : "" }" +
                     " #{opts[:empty_ok] ? "--allow-empty" : "" }" +
                     " #{opts[:message] ? "-m #{opts[:message].inspect}" : "" }"
            string.strip!
            
            git string
            self[:tip].node
          end
          
          def add_all_files
            staging_area.add status[:modified]
          end
          
          def forget(*files)
            staging_area.forget *files
          end
          
          def [](rev)
            case rev
            when NodeId, String
              Amp::Rugged::Changeset.new self, rev
            when nil
              Amp::Rugged::WorkingDirectoryChangeset.new self
            when 'tip', :tip
              Amp::Rugged::Changeset.new self, parents[0]
            when Integer
              revs = git('log --pretty=oneline').split("\n")
              short_name = revs[revs.size - 1 - rev].split(' ').first
              Amp::Rugged::Changeset.new self, short_name
            end
          end
          
          def size
            git('log --pretty=oneline').split("\n").size
          end
          
          ##
          # Write +text+ to +filename+, where +filename+
          # is local to the root.
          #
          # @param [String] filename The file as relative to the root
          # @param [String] text The text to write to said file
          def working_write(filename, text)
            file_opener.open filename, 'w' do |f|
              f.write text
            end
          end
          
          ##
          # Determines if a file has been modified from :node1 to :node2.
          # 
          # @return [Boolean] has it been modified
          def file_modified?(file, opts={})
            file_status(file, opts) == :included
          end
          
          ##
          # Returns a Symbol.
          # Possible results:
          # :added (subset of :included)
          # :removed
          # :untracked
          # :included (aka :modified)
          # :normal
          # 
          # If you call localrepo#status from this method... well...
          # I DARE YOU!
          def file_status(filename, opts={})
            parse_status! opts
            inverted = @status.inject({}) do |h, (k, v)|
              v.each {|v_| h[v_] = k }
              h
            end
            
            # Now convert it so it uses the same jargon
            # we REALLY need to get the dirstate and localrepo on
            # the same page here.
            case inverted[filename]
            when :modified
              :included
            when :added
              :added
            when :removed
              :removed
            when :unknown
              :untracked
            else
              :normal
            end
              
          end

          def refresh!
            @parsed = false
            staging_area.refresh!
          end
          
          def parse_status!(opts={})
            return if @parsed
            
            p opts[:node1], opts[:node2]
            if (opts[:node1] && opts[:node2])
              data    = git("status #{opts[:node1]}..#{opts[:node2]}").split("\n")
            else
              data    = git("status").split("\n")
            end
            #puts data
            @status = Hash.new {|h,k| h[k] = []}
            data.each do |line| # yeah i know stfu
              case line
              when /^#\s+(\w+):\s(.+)$/
                @status[$1.to_sym] << $2.strip
              when /^#\s+([^ ]+)$/
                @status[:unknown] << $1.strip
              else
                @status
              end
            end
            #p @status
            @parsed = true
          end
          
          def parents
            first = git('log -1 HEAD')
            dad   = first[/^commit (.+)$/, 1]
            dad   = dad ? NodeId.from_hex(dad) : nil
            mom   = nil
            
            if first =~ /Merge: (.+)\.\.\. (.+)\.\.\.$/ # Merge: 1c002dd... 35cfb2b...
              dad = NodeId.from_hex($1) # just have them both use the short name, nbd
              mom = NodeId.from_hex($2)
            end
            
            [dad, mom]
          end
          
        end
      end
    end
  end
end
