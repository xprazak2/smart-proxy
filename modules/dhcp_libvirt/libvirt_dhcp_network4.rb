require 'dhcp_libvirt/libvirt_dhcp_network'

module ::Proxy::DHCP::Libvirt
  class LibvirtDHCPNetwork4 < LibvirtDHCPNetwork
    def change_record(record, nametag)
     "<host mac=\"#{record.mac}\" ip=\"#{record.ip}\" #{nametag}/>"
    end
  end
end
