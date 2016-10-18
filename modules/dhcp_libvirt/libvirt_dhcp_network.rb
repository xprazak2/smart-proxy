require 'libvirt'
require 'libvirt_common/libvirt_network'

module ::Proxy::DHCP::Libvirt
  class LibvirtDHCPNetwork < Proxy::LibvirtNetwork
    attr_reader :parser

    def initialize(url, network, parser)
      super url, network
      @parser = parser
    end

    def dhcp_leases
      find_network.dhcp_leases
    rescue ArgumentError
      # workaround for ruby-libvirt < 0.6.1 - DHCP leases API is broken there
      # (http://libvirt.org/git/?p=ruby-libvirt.git;a=commit;h=c2d4192ebf28b8030b753b715a72f0cdf725d313)
      []
    end

    def subnets
      parser.parse_config_for_subnets(dump_xml)
    end

    def dhcp_hosts(subnet)
      parser.parse_config_for_reservations(subnet, dump_xml)
    end

    def add_dhcp_record(record)
      xml = change_xml record
      network_update ::Libvirt::Network::UPDATE_COMMAND_ADD_LAST, ::Libvirt::Network::NETWORK_SECTION_IP_DHCP_HOST, xml, parser.index
    end

    def del_dhcp_record(record)
      xml = change_xml record
      network_update ::Libvirt::Network::UPDATE_COMMAND_DELETE, ::Libvirt::Network::NETWORK_SECTION_IP_DHCP_HOST, xml, parser.index
    end

    def change_xml(record)
      nametag = "name=\"#{record.name}\"" if record.name
      change_record(record, nametag)
    end
  end
end
