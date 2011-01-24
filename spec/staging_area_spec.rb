require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'amp_repo_spec/staging_area'

describe Amp::Core::Repositories::Rugged::StagingArea do
  ModuleUnderTest = Amp::Core::Repositories::Rugged
  it_should_behave_like 'staging_area'
end
