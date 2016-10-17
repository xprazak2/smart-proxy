module Proxy::DHCP::Libvirt
  class SubnetLoader
    attr_reader :service, :libvirt_networks

    def initialize(subnet_service, libvirt_networks)
      @libvirt_networks = libvirt_networks
      @service = subnet_service
    end

    def start
      load_subnets
    end

    def load_subnets
      subnets = libvirt_networks.flat_map(&:subnets)
      service.add_subnets(*subnets)
      # service.add_subnets(*libvirt_network.subnets)
    end

    def load_records(subnet, xml)
      reservations = parse_config_for_dhcp_reservations(subnet, xml)
      reservations.each { |record| service.add_host(record.subnet_address, record) }
    end
  end
end