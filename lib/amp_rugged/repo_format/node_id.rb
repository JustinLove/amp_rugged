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
##################################################################

module Amp::Core::Repositories::Rugged
  class NodeId < Amp::Core::Support::HexString
    def hexlify
      if @binary.size == 20
        ::Rugged::raw_to_hex(@binary)
      else
        super
      end
    end

    def unhexlify
      if @hex.size == 40
        ::Rugged::hex_to_raw(@hex)
      else
        super
      end
    end
  end
end
