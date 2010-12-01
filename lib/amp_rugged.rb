puts 'Loading amp_rugged...'

require 'zlib'
require 'stringio'

# Must require the GitPicker or it won't be found.
require 'rugged'
require 'amp-front'
require 'amp-core'
require 'amp_rugged/repository'


module Amp
  module Rugged
    autoload :Changeset,                 'amp_rugged/repo_format/changeset.rb'
    autoload :WorkingDirectoryChangeset, 'amp_rugged/repo_format/changeset.rb'
    autoload :VersionedFile,             'amp_rugged/repo_format/versioned_file.rb'
    autoload :VersionedWorkingFile,      'amp_rugged/repo_format/versioned_file.rb'
  end
  module Core
    module Repositories
      module Rugged
        include Support
        autoload :LocalRepository,         'amp_rugged/repositories/local_repository.rb'
        autoload :NodeId,                  'amp_rugged/repo_format/node_id.rb'
        autoload :StagingArea,             'amp_rugged/repo_format/staging_area.rb'
        autoload :RawObject,               'amp_rugged/repo_format/raw_object.rb'
        autoload :LooseObject,             'amp_rugged/repo_format/loose_object.rb'
        autoload :CommitObject,            'amp_rugged/repo_format/commit_object.rb'
        autoload :Index,                   'amp_rugged/repo_format/index.rb'
        module Encoding                             
          autoload :BinaryDelta,           'amp_rugged/encoding/binary_delta.rb'
        end
      end
    end
  end
end

require 'amp_rugged/version'
