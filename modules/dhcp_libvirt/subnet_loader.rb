module Proxy::DHCP::Libvirt
  class SubnetLoader
    attr_reader :deps

    def initialize(deps)
      @deps = deps
    end

    def start
      load_subnets
      load_subnet_data
    end

    def load_subnets
      deps.each do |service, libvirt_network|
        service.add_subnets(*libvirt_network.subnets)
      end
    end

    def load_subnet_data
      deps.each do |service, libvirt_network|
        service.all_subnets.each do |subnet|
          load_records subnet, libvirt_network, service
        end
      end
      load_leases
    end

    def load_records(subnet, libvirt_network, service)
      reservations = libvirt_network.dhcp_hosts(subnet)
      reservations.each { |record| service.add_host(record.subnet_address, record) }
    end

    def load_leases
      deps.each do |service, libvirt_network|
        leases = libvirt_network.dhcp_leases
        leases.each do |element|
          lease = Proxy::DHCP::Lease.new(
            :subnet => subnet,
            :ip => element['ipaddr'],
            :mac => element['mac'],
            :starts => Time.now.utc,
            :ends => Time.at(element['expirytime'] || 0).utc,
            :state => 'active'
          )
          service.add_lease(lease.subnet_address, lease)
       end
      end
    end
  end
end
