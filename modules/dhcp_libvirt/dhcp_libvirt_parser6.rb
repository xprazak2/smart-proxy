require 'rexml/document'

module Proxy::DHCP::Libvirt
  class Parser6
    attr_reader :service
    attr_accessor :index

    def initialize(subnet_service)
      @service = subnet_service
    end

    def parse_config_for_subnets(xml)
      ret_val = []
      doc = REXML::Document.new xml
      doc.elements.each_with_index("network/ip") do |elem, idx|
        if elem.attributes["family"] == "ipv6"
          ret_val << parse_subnet(elem)
          index = idx
        end
      end
      raise Proxy::DHCP::Error("Only one subnet is supported") if ret_val.count > 1
      ret_val
    rescue Exception => e
      logger.error msg = "Unable to parse subnets XML: #{e}"
      logger.debug xml if defined?(xml)
      raise Proxy::DHCP::Error, msg
    end

    def parse_subnet(elem)
      gateway = elem.attributes["address"]
      prefix = elem.attributes["prefix"]
      Proxy::DHCP::Ipv6.new(gateway, prefix)
    end

    def parse_reservations(subnet, xml)
      ret_val = []
      REXML::Document.new xml
      REXML::XPath.each(doc, "//network/ip[@family='ipv6']/dhcp/host") do |e|
        ret_val << Proxy::DHCP::Reservation.new(
          :subnet => subnet,
          :ip => e.attributes["ip"],
          :id => e.attributes["id"],
          :hostname => e.attributes["name"])
      end
      ret_val
    end

    # def load_subnets(xml)
    #   service.add_subnets(*parse_config_for_subnets(xml))
    # end


    # def load_records(subnet, xml)
    #   reservations = parse_config_for_dhcp_reservations(subnet, xml)
    #   reservations.each { |record| service.add_host(record.subnet_address, record) }
    # end
  end
end