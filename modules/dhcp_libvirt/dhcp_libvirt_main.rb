module Proxy::DHCP::Libvirt
  class Provider < ::Proxy::DHCP::Server
    attr_reader :network, :libvirt_network, :ip_reserver

    def initialize(network, libvirt_network, subnet_service, ip_reserver)
      @network = network
      @libvirt_network = libvirt_network
      @ip_reserver = ip_reserver
      super(@network, nil, subnet_service)
    end

    def load_subnets
      logger.debug "load_subnets method should not be called"
      # super
      # parser.load_subnets
    end

    def load_subnet_data(subnet)
      logger.debug "load_subnet_data method should not be called"
      # super(subnet)
      # parser.load_subnet_data(subnet)
      # libvirt_network.load_subnet_data(subnet)
    end

    def subnets
      libvirt_network.subnets
      # super
    end

    def unused_ip(network, mac, from_addr, to_addr)
      ip_reserver.unused_ip(network, mac, from_addr, to_addr)
    end

    def all_hosts(subnet_addr)
      libvirt_network.dhcp_hosts
      # super
    end

    def all_leases(subnet_addr)
      libvirt_network.dhcp_leases.map do |element|
        lease = Proxy::DHCP::Lease.new(
          :subnet => subnet,
          :ip => element['ipaddr'],
          :mac => element['mac'],
          :starts => Time.now.utc,
          :ends => Time.at(element['expirytime'] || 0).utc,
          :state => 'active'
        )
      end
    end

    def add_record(options={})
      record = super(options)
      libvirt_network.add_dhcp_record record
      record
    rescue ::Libvirt::Error => e
      logger.error msg = "Error adding DHCP record: #{e}"
      raise Proxy::DHCP::Error, msg
    end

    def del_record(_, record)
      # libvirt only supports one subnet per network
      libvirt_network.del_dhcp_record record
    rescue ::Libvirt::Error => e
      logger.error msg = "Error removing DHCP record: #{e}"
      raise Proxy::DHCP::Error, msg
    end
  end
end
