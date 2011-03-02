require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'amp_repo_spec/changeset'

describe Amp::Rugged::Changeset do
  ModuleUnderTest = Amp::Core::Repositories::Rugged
  it_should_behave_like 'changeset'
end
