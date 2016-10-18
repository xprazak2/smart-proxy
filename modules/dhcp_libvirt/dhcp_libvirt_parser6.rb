require 'rexml/document'

module Proxy::DHCP::Libvirt
  class Parser6
    include Proxy::Log

    attr_accessor :index

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
      logger.debug xml if xml
      raise Proxy::DHCP::Error, msg
    end

    def parse_subnet(elem)
      gateway = elem.attributes["address"]
      prefix = elem.attributes["prefix"]
      network = IPAddr.new(gateway).mask(prefix).to_s
      Proxy::DHCP::Ipv6.new(network, prefix)
    end

    def parse_config_for_reservations(subnet, xml)
      result = []
      doc = REXML::Document.new xml
      REXML::XPath.each(doc, "//network/ip[@family='ipv6']/dhcp/host") do |e|
        result << Proxy::DHCP::Reservation.new(
          :subnet => subnet,
          :ip => e.attributes["ip"],
          :id => e.attributes["id"],
          :hostname => e.attributes["name"])
      end
      result
    end
  end
end
