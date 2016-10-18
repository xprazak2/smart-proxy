require 'dhcp_common/subnet'

module Proxy::DHCP
  class Ipv4 < Subnet
    attr_reader :netmask

    def initialize network, netmask, options = {}
      @netmask = validate_ip netmask
      super network, options
    end

    def to_s
      "#{network}/#{netmask}"
    end

    def prefix
      IPAddr.new(netmask).to_i.to_s(2).count("1")
    end

    def valid_range args = {}
      total_range(args).map(&:to_s) - [network, broadcast]
    end

    def broadcast
      IPAddr.new(to_s).to_range.last.to_s
    end
  end
end
