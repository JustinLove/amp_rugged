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
        class StagingArea < Amp::Core::Repositories::AbstractStagingArea
          def git(command)
            #p repo.root
            #p command
            %x{git --git-dir=#{repo.root}/.git --work-tree=#{repo.root} #{command} 2> /dev/null}
          end
          
          attr_accessor :repo
          
          def initialize(repo)
            @repo = repo
          end
          
          ##
          # Marks a file to be added to the repository upon the next commit.
          # 
          # @param [[String]] filenames a list of files to add in the next commit
          # @return [Boolean] true for success, false for failure
          def add(*filenames)
            git("add #{filenames.join ' '}")
            true
          end

          ##
          # The directory used by the VCS to store magical information (.hg, .git, etc.).
          #
          # @api
          # @return [String] relative to root
          def vcs_dir
            '.git'
          end

          ##
          # Marks a file to be removed from the repository upon the next commit. Last argument
          # can be a hash, which can take an :unlink key, specifying whether the files should actually
          # be removed or not.
          # 
          # @param [String, Array<String>] filenames a list of files to remove in the next commit
          # @return [Boolean] true for success, false for failure
          def remove(*filenames)
            git("rm -f #{filenames.join ' '}")
            true
          end

          ##
          # Set +file+ as normal and clean. Un-removes any files marked as removed, and
          # un-adds any files marked as added.
          # 
          # @param  [String, Array<String>] files the name of the files to mark as normal
          # @return [Boolean] success marker
          def normal(*files)
            # Do nothing...
            true
          end
          
          ##
          # Mark the files as untracked.
          # 
          # @param  [Array<String>] files the name of the files to mark as untracked
          # @return [Boolean] success marker
          def forget(*files)
            git("rm --cached #{files.join ' '}")
            true
          end

          ##
          # Marks a file to be copied from the +from+ location to the +to+ location
          # in the next commit, while retaining history.
          # 
          # @param [String] from the source of the file copy
          # @param [String] to the destination of the file copy
          # @return [Boolean] true for success, false for failure
          def copy(from, to)
            Dir.chdir(repo.root) do
              system("cp #{from} #{to}")
            end
            add(to)
            true
          end

          ##
          # Marks a file to be moved from the +from+ location to the +to+ location
          # in the next commit, while retaining history.
          # 
          # @param [String] from the source of the file move
          # @param [String] to the destination of the file move
          # @return [Boolean] true for success, false for failure
          def move(from, to)
            git("mv #{from} #{to}")
            true
          end

          ##
          # Marks a modified file to be included in the next commit.
          # If your VCS does this implicitly, this should be defined as a no-op.
          # 
          # @param [String, Array<String>] filenames a list of files to include for committing
          # @return [Boolean] true for success, false for failure
          def include(*filenames)
            add filenames
          end
          alias_method :stage, :include

          ##
          # Mark a modified file to not be included in the next commit.
          # If your VCS does not include this idea because staging a file is implicit, this should
          # be defined as a no-op.
          # 
          # @param [[String]] filenames a list of files to remove from the staging area for committing
          # @return [Boolean] true for success, false for failure
          def exclude(*filenames)
            git("reset HEAD #{filenames.join ' '}")
            true
          end
          alias_method :unstage, :exclude

          ##
          # Returns a Symbol.
          # 
          # If you call localrepo#status from this method... well...
          # I DARE YOU!
          def file_status(filename)
            parse!
            inverted = {}
            @status.each do |k, v|
              v.each {|v_| inverted[v_] = k }
            end
            
            # lame hack, i know
            val = inverted[filename]
            return :normal if (val.nil? && all_files.include?(filename))
            return val
          end
          
          # modified, lookup, or clean
          # in this case, since we're shelling out,
          # only modified or clean
          def file_precise_status(filename, st)
            parse!
            inverted = @status.inject({}) do |h, (k, v)|
              v.each {|v_| h[v_] = k }
              h
            end
            
            # bleh this code sucks
            if inverted[filename] == :modified
              :modified
            else
              :clean
            end
          end
          
          ##
          # Calculates the difference (in bytes) between a file and its last tracked state.
          #
          # Supplements the built-in #status method so that its output will include deltas.
          #
          # @apioptional
          # @param [String] file the filename to look up
          # @param [File::Stats] st the current results of File.lstat(file)
          # @return [Fixnum] the number of bytes difference between the file and
          #  its last tracked state.
          def calculate_delta(file, st)
            0
          end
          
          def refresh!
            @parsed = false
          end

          def parse!
            return if @parsed

            state = :staging
            
            @status = Hash.new {|h,k| h[k] = [] }
            data    = git("status").split("\n")
            data.each do |line|
              case line
              when /Changed but not updated/
                break
              when /^#\s+renamed:\s(.+)\s->\s(.+)$/
                @status[:removed] << $1.strip
                @status[:added] << $2.strip
              when /^#\s+deleted:\s(.+)$/
                @status[:removed] << $1.strip
              when /^#\s+(\w+):\s(.+)$/
                @status[$1.to_sym] << $2.strip
              when /^#\s+new file:\s(.+)$/
                @status[:added] << $1.strip
              else
                @status
              end
            end
            
            @parsed = true
          end

          ##
          # Saves the staging area's state.  Any added files, removed files, "normalized" files
          # will have that status saved here.
          def save
            #noop, shelling out always affects the filesystem
          end

          ##
          # Returns all files tracked by the repository *for the working directory* - not
          # to be confused with the most recent changeset.
          #
          # @api
          # @return [Array<String>] all files tracked by the repository at this moment in
          #   time, including just-added files (for example) that haven't been committed yet.
          def all_files
            Index.new('index', @repo.git_opener).to_a
          end
        end
      end
    end
  end
end
