module Proxy::DHCP::Libvirt
  class Provider < ::Proxy::DHCP::Server
    attr_reader :network, :libvirt_network, :ip_reserver

    def initialize(network, libvirt_network, subnet_service, ip_reserver)
      @network = network
      @libvirt_network = libvirt_network
      @ip_reserver = ip_reserver
      super(@network, nil, subnet_service)
    end

    def unused_ip(network, mac, from_addr, to_addr)
      ip_reserver.unused_ip(network, mac, from_addr, to_addr)
    end

    def add_record(options={})
      record = super(options)
      libvirt_network.add_dhcp_record record
      service.add_host(service.find_subnet(options['network']), record)
      record
    rescue ::Libvirt::Error => e
      logger.error msg = "Error adding DHCP record: #{e}"
      raise Proxy::DHCP::Error, msg
    end

    def del_record(_, record)
      # libvirt only supports one subnet per network
      libvirt_network.del_dhcp_record record
      service.delete_host(record)
    rescue ::Libvirt::Error => e
      logger.error msg = "Error removing DHCP record: #{e}"
      raise Proxy::DHCP::Error, msg
    end
  end
end
