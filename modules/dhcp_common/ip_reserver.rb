module Proxy::DHCP
  class IpReserver
    attr_reader :service

    def initialize subnet_service
      @service = subnet_service
    end

    def record_by_mac_address network, mac_address
      return nil unless mac_address
      service.find_host_by_mac(network, mac_address) || service.find_lease_by_mac(network, mac_address)
    end

    def ip_by_range record, from_addr, to_addr
      if record && subnet.valid_range(:from => from_addr, :to => to_addr).include?(record.ip)
        logger.debug "Found an existing DHCP record #{record}, reusing..."
        return record.ip
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

    def icmp_pingable?
    rescue => err
      # We failed to check this address so we should not use it
      logger.warn "Unable to icmp ping #{ip} because #{err.inspect}. Skipping this address..."
      true
    end
  end
end
