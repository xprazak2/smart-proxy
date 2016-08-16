require 'dhcp_libvirt/libvirt_dhcp_network'

module ::Proxy::DHCP::Libvirt
  class LibvirtDHCPNetwork6 < LibvirtDHCPNetwork
    def change_record(record, nametag)
      id_tag = "id=\"#{record.id}\"" if record.id
      "<host #{id_tag} ip=\"#{record.ip}\" #{nametag}/>"
    end
  end
end
