module Proxy::DHCP::Libvirt
  class PluginConfiguration
    def load_dependency_injection_wirings(container, settings)
      container.dependency :memory_store, ::Proxy::MemoryStore
      container.singleton_dependency :subnet_service, (lambda do
        ::Proxy::DHCP::SubnetService.new(container.get_dependency(:memory_store), container.get_dependency(:memory_store),
                                         container.get_dependency(:memory_store), container.get_dependency(:memory_store),
                                         container.get_dependency(:memory_store), container.get_dependency(:memory_store))
      end)
      container.dependency :ip_reserver4, (lambda do
        ::Proxy::DHCP::IpReserver4.new(container.get_dependency(:subnet_service))
      end)
      container.dependency :parser4, (lambda do
        ::Proxy::DHCP::Libvirt::Parser4.new(container.get_dependency(:subnet_service))
      end)
      container.dependency :libvirt_network4, (lambda do
        ::Proxy::DHCP::Libvirt::LibvirtDHCPNetwork.new(settings[:url], settings[:network], container.get_dependency(:parser4))
      end)

      container.dependency :ip_reserver6, (lambda do
        ::Proxy::DHCP::IpReserver6.new(container.get_dependency(:subnet_service))
      end)
      container.dependency :parser6, (lambda do
        ::Proxy::DHCP::Libvirt::Parser6.new(container.get_dependency(:subnet_service))
      end)
      container.dependency :libvirt_network6, (lambda do
        ::Proxy::DHCP::Libvirt::LibvirtDHCPNetwork.new(settings[:url], settings[:network], container.get_dependency(:parser6))
      end)

      container.dependency :dhcp_provider, (lambda do
        Proxy::DHCP::Libvirt::Provider.new(settings[:network],
                                           container.get_dependency(:libvirt_network4),
                                           container.get_dependency(:subnet_service),
                                           container.get_dependency(:ip_reserver4))
      end)

      container.dependency :dhcp_provider6, (lambda do
        Proxy::DHCP::Libvirt::Provider.new(settings[:network],
                                           container.get_dependency(:libvirt_network6),
                                           container.get_dependency(:subnet_service),
                                           container.get_dependency(:ip_reserver6))
      end)

      container.dependency :subnet_loader, (lambda do
        Proxy::DHCP::Libvirt::SubnetLoader.new(container.get_dependency(:subnet_service),
                                               [container.get_dependency(:libvirt_network4),
                                                container.get_dependency(:libvirt_network6)])
      end)
    end

    def load_classes
      require 'dhcp_libvirt/libvirt_dhcp_network'
      require 'dhcp_common/subnet_service'
      require 'dhcp_common/ip_reserver4'
      require 'dhcp_common/ip_reserver6'
      require 'dhcp_common/server'
      require 'dhcp_libvirt/dhcp_libvirt_main'
      require 'dhcp_libvirt/dhcp_libvirt_parser4'
      require 'dhcp_libvirt/dhcp_libvirt_parser6'
      require 'dhcp_common/subnet/ipv4'
      require 'dhcp_common/subnet/ipv6'
    end
  end
end
