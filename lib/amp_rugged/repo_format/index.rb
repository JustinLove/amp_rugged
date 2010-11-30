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

# This was written by reading the Git Book. No source code was
# examined to produce this code. It is the original work of its
# creators, Michael Edgar and Ari Brown.
#
# http://book.git-scm.com/7_the_packfile.html
# http://repo.or.cz/w/git.git?a=blob;f=Documentation/technical/pack-format.txt;h=1803e64e465fa4f8f0fe520fc0fd95d0c9def5bd;hb=HEAD
# http://git.rsbx.net/Documents/Git_Data_Formats.txt

module Amp
  module Core
    module Repositories
      module Rugged
        ##
        # = Index
        #
        # The Index is essentially a cache of the working directory. It tracks
        # which files have been added to the staging area and which have not, and
        # can be used to check if a file has been modified or not. It is a relatively
        # complex binary format and there are two versions of it we also have to
        # support.
        class Index
          
          class IndexParseError < StandardError; end
          
          ##
          # Parses the given file as an Index, and returns the appropriate subclass of Index.
          # There are two versions that are supported and each needs to be able to handle
          # status lookups and so on.
          #
          # @param [String] file the name of the file to open
          # @param [Support::RootedOpener] opener an opener to scope the opening of files
          # @return [Index] the index object this file represents
          class << self
            alias_method :parse, :new
          end

          def initialize(file, opener)
            path = File.join opener.root, file
            begin
              @index = ::Rugged::Index.new(path)
              @index.refresh
            rescue
              raise IndexParseError
            end
            @entry_map = {}
            @index.each do |entry|
              entry.extend(IndexEntryExtensions)
              @entry_map[entry.path] = entry
            end
          end
          
          ##
          # The format of each index entry is as follows:
          #   create_time, 32-bits # in seconds, least-significant bits if rollover
          #   create_time_nanoseconds, 32-bits 
          #   modify_time, 32-bits # in seconds, least-significant bits if rollover
          #   modify_time_nanoseconds, 32-bits
          #   device, 32-bits # device id
          #   inode, 32-bits # inode from the filesystem
          #   mode, 32-bits # permissions/mode from the FS
          #   uid, 32-bits # user ID from the FS
          #   gid, 32-bits # group ID from the FS
          #   size, 32-bits # filesize, least-significant-bits, from FS
          #   hash_id, 20 bytes # sha-1 hash of the data
          #   assume_valid, 1 bit # flag for whether this file should be assumed to be unchanged
          #   update_needed, 1 bit # flag saying the file needs to be refreshed
          #   stage, 2 bits # two flags used for merging
          #   filename_size, 12 bits # the size of the upcoming filename in bytes
          #   filename, N bytes # the name of the file in the index
          #   padding, N bytes # null padding. At least 1 byte, enough to make the block's size a
          #     multiple of 8 bytes
          #
          module IndexEntryExtensions
            def hash_id
              NodeId.from_hex(sha)
            end
          end
          
          ##
          # @return [Integer] the number of entries in the Index.
          def size
            @index.entry_count
          end
          
          ##
          # Returns an IndexEntry for the file with the given name.
          # Returns nil on failure, and this should not be used by end-users
          #
          # @param [String] name the name of the object/file to look up
          # @return [IndexEntry, NilClass] the entry with the given name, or nil
          def [](name)
            @entry_map[name]
          end
          
          def inspect
            "<Git Index, entries: #{@entry_count}>"
          end
        end
      end
    end
  end
end
