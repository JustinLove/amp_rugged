require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'amp_repo_spec/local_repository'

describe Amp::Core::Repositories::Rugged::LocalRepository do
  ModuleUnderTest = Amp::Core::Repositories::Rugged
  it_should_behave_like 'local repository'
end
