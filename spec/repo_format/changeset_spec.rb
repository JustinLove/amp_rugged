require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'amp_repo_spec/changeset'
require 'amp_repo_spec/working_directory_changeset'

describe Amp::Rugged::Changeset do
  ModuleUnderTest = Amp::Core::Repositories::Rugged
  it_should_behave_like 'changeset'
end

describe Amp::Rugged::WorkingDirectoryChangeset do
  ModuleUnderTest = Amp::Core::Repositories::Rugged
  it_should_behave_like 'working_directory_changeset'
end
