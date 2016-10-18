require 'dhcp_common/ip_reserver'

module Proxy::DHCP
  class IpReserver4 < IpReserver

    def unused_ip network, mac_address, from_address, to_address
      # first check if we already have a record for this host
      # if we do, we can simply reuse the same ip address.
      subnet = service.find_subnet network
      record = record_by_mac_address(subnet, mac_address)
      return record.ip if ip_by_range(record, from_address, to_address)

      find_unused_ip(subnet, service.all_hosts(network) + service.all_leases(network),
                     :from => from_address, :to => to_address)
    end

    def ip_by_mac_address_and_range network, mac_address, from_address, to_address
      return nil unless mac_address
      r = service.find_host_by_mac(network, mac_address) ||
          service.find_lease_by_mac(network, mac_address)

      if r && subnet.valid_range(:from => from_address, :to => to_address).include?(r.ip)
        logger.debug "Found an existing DHCP record #{r}, reusing..."
        return r.ip
      end
    end

    # NOTE: stored index is indepndent of call parameters:
    # Whether range is passed or not, the lookup starts with the address at the indexed position,
    # Is the assumption that unused_ip is always called with the same parameters for a given subnet?
    #
    # returns the next unused IP Address in a subnet
    # Pings the IP address as well (just in case its not in Proxy::DHCP)
    def find_unused_ip subnet, records, args = {}
      free_ips = subnet.valid_range(args) - records.collect { |record| record.ip }
      if free_ips.empty?
        logger.warn "No free IPs at #{self}"
        return nil
      else
        @index = 0
        begin
          # Read and lock the storage file
          stored_index = get_index_and_lock("foreman-proxy_#{subnet.network}_#{subnet.prefix}.tmp")
          free_ips.rotate(stored_index).each do |ip|
            logger.debug "Searching for free IP - pinging #{ip}"
            if tcp_pingable?(ip) || icmp_pingable?(ip)
              logger.debug "Found a pingable IP(#{ip}) address which does not have a Proxy::DHCP record"
            else
              logger.debug "Found free IP #{ip} out of a total of #{free_ips.size} free IPs"
              @index = free_ips.index(ip) + 1
              return ip
            end
          end
          logger.warn "No free IPs at #{self}"
        rescue Exception => e
          logger.debug e.message
        ensure
          # ensure we unlock the storage file
          write_index_and_unlock @index
        end
        nil
      end
    end

    def icmp_pingable? ip
      system("ping -c 1 -W 1 #{ip} > /dev/null")
      super()
    end
  end
end
