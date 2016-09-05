require 'checks'
require 'ipaddr'
require 'dhcp_common/monkey_patches' unless IPAddr.new.respond_to?('to_range')
require 'dhcp_common/monkey_patch_subnet' unless Array.new.respond_to?('rotate')
require 'proxy/validations'
require 'socket'
require 'timeout'
require 'tmpdir'

module Proxy::DHCP
  # Represents a DHCP Subnet
  class Subnet
    attr_reader :network, :server, :timestamp
    attr_accessor :options

    include Proxy::DHCP
    include Proxy::Log
    include Proxy::Validations

    def initialize network, options = {}
      @network = validate_ip network
      @options = {}

      @options[:routers] = options[:routers].each{|ip| validate_ip ip } if options[:routers]
      @options[:domain_name] = options[:domain_name] if options[:domain_name]
      @options[:domain_name_servers] = options[:domain_name_servers].each{|ip| validate_ip ip } if options[:domain_name_servers]
      @options[:ntp_servers] = options[:ntp_servers].each{|ip| validate_ip ip } if options[:ntp_servers]
      @options[:interface_mtu] = options[:interface_mtu].to_i if options[:interface_mtu]
      @options[:range] = options[:range] if options[:range] && options[:range][0] && options[:range][1] && valid_range(:from => options[:range][0], :to => options[:range][1])

      @timestamp     = Time.now
    end

    def include? ip
      if ip.is_a?(IPAddr)
        ipaddr = ip
      else
        begin
          ipaddr = IPAddr.new(ip)
        rescue
          logger.debug("Ignoring invalid IP address #{ip}")
          return false
        end
      end

      IPAddr.new(to_s).include?(ipaddr)
    end

    def range
      r = valid_range
      "#{r.first}-#{r.last}"
    end


    def inspect
      self
    end

    def <=> other
      network <=> other.network
    end

    private

    def total_range args = {}
      logger.debug "trying to find an ip address, we got #{args.inspect}"
      if args[:from] && (from = validate_ip(args[:from])) && args[:to] && (to = validate_ip(args[:to]))
        raise Proxy::DHCP::Error, "Range does not belong to provided subnet" unless self.include?(from) && self.include?(to)
        from = IPAddr.new(from)
        to   = IPAddr.new(to)
        raise Proxy::DHCP::Error, "#{from} can't be lower IP address than #{to} - change the order?" if from > to
        from..to
      else
        IPAddr.new(to_s).to_range
      end
    end
  end
end
