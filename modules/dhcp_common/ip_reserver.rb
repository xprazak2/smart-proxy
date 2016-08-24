module Proxy::DHCP
  class IpReserver
    attr_reader :service

    def initialize(subnet_service)
      @service = subnet_service
    end

    ##### moved from server
    def unused_ip(network, mac_address, from_address, to_address)
      # first check if we already have a record for this host
      # if we do, we can simply reuse the same ip address.
      subnet = service.find_subnet network
      r = ip_by_mac_address_and_range(subnet, mac_address, from_address, to_address)
      return r if r
      nil

      find_unused_ip(subnet, service.all_hosts(network) + service.all_leases(network),
                     :from => from_address, :to => to_address)
    end

    def ip_by_mac_address_and_range(network, mac_address, from_address, to_address)
      return nil unless mac_address
      r = service.find_host_by_mac(network, mac_address) ||
          service.find_lease_by_mac(network, mac_address)

      if r && subnet.valid_range(:from => from_address, :to => to_address).include?(r.ip)
        logger.debug "Found an existing DHCP record #{r}, reusing..."
        return r.ip
      end
    end
    #####

    ##### moved from subnet
    # NOTE: stored index is indepndent of call parameters:
    # Whether range is passed or not, the lookup starts with the address at the indexed position,
    # Is the assumption that unused_ip is always called with the same parameters for a given subnet?
    #
    # returns the next unused IP Address in a subnet
    # Pings the IP address as well (just in case its not in Proxy::DHCP)
    def find_unused_ip subnet, records, args = {}
      free_ips = subnet.valid_range(args) - records.collect{|record| record.ip}
      if free_ips.empty?
        logger.warn "No free IPs at #{self}"
        return nil
      else
        @index = 0
        begin
          # Read and lock the storage file
          stored_index = get_index_and_lock("foreman-proxy_#{network}_#{prefix}.tmp")
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

    def get_index_and_lock filename
      # Store for use in the unlock method
      @filename = "#{Dir::tmpdir}/#{filename}"
      @lockfile = "#{@filename}.lock"

      # Loop if the file is locked
      Timeout::timeout(30) { sleep 0.1 while File.exist? @lockfile }

      # Touch the lock the file
      File.open(@lockfile, "w") {}

      @file = File.new(@filename,'r+') rescue File.new(@filename,'w+')

      # this returns the index in the file
      return index_from_file(@file)
    end

    def write_index_and_unlock index
      @file.reopen(@filename,'w')
      @file.write index
      @file.close
      File.delete @lockfile
    end

    def tcp_pingable? ip
      # This code is from net-ping, and stripped down for use here
      # We don't need all the ldap dependencies net-ping brings in

      @service_check = true
      @port          = 7
      @timeout       = 1
      @exception     = nil
      bool           = false
      tcp            = nil

      begin
        Timeout.timeout(@timeout) do
          begin
            tcp = TCPSocket.new(ip, @port)
          rescue Errno::ECONNREFUSED => err
            if @service_check
              bool = true
            else
              @exception = err
            end
          rescue Exception => err
            @exception = err
          else
            bool = true
          end
        end
      rescue Timeout::Error => err
        @exception = err
      ensure
        tcp.close if tcp
      end

      bool
    rescue
      # We failed to check this address so we should not use it
      true
    end

    def icmp_pingable? ip
      # Always shell to ping, instead of using net-ping
    if PLATFORM =~ /mingw/
      # Windows uses different options for ping and does not have /dev/null
      system("ping -n 1 -w 1000 #{ip} > NUL")
    elsif self.is_a? Subnet::Ipv6
      # use ping6 for IPv6
      system("ping6 -c 1 -W 1 #{ip} > /dev/null")
    else
      # Default to Linux ping options and send to /dev/null
      system("ping -c 1 -W 1 #{ip} > /dev/null")
    end
    rescue => err
      # We failed to check this address so we should not use it
      logger.warn "Unable to icmp ping #{ip} because #{err.inspect}. Skipping this address..."
      true
    end
  end
end
