module Amp
  module Core
  end
  module Support
  end
end

class Amp::Plugins::Rugged < Amp::Plugins::Base
  def initialize(opts={})
    @opts = opts
  end
  
  def load!
    require 'amp_rugged'
  end
end
