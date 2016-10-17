require 'dhcp_libvirt/subnet_loader'

module ::Proxy::DHCP::Libvirt
  class Plugin < ::Proxy::Provider
    plugin :dhcp_libvirt, ::Proxy::VERSION

    requires :dhcp, ::Proxy::VERSION
    default_settings :url => "qemu:///system", :network => 'default'

    load_classes ::Proxy::DHCP::Libvirt::PluginConfiguration
    load_dependency_injection_wirings ::Proxy::DHCP::Libvirt::PluginConfiguration

    start_services :subnet_loader
  end
end
