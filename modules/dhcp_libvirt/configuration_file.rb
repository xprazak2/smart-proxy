module Proxy::DHCP::Libvirt
  class ConfigurationFile
    attr_accessor :index_v4, :index_v6

    def index(record)
      record.v6? ? index_v6 : index_v4
    end
  end
end
