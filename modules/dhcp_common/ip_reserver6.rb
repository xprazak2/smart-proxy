require 'dhcp_common/ip_reserver'

module Proxy::DHCP
  class IpReserver6 < IpReserver
    def icmp_pingable? ip
      system("ping6 -c 1 -W 1 #{ip} > /dev/null")
      super()
    end
  end
end