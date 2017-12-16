#
# Cookbook Name:: wazuh
# Recipe:: manager
#
# Copyright 2015, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#include_recipe 'chef-sugar::default'
include_recipe 'apt::default'
include_recipe 'wazuh_ossec::repository'

package 'wazuh-manager' do
  package_name 'wazuh-manager'
end

<<<<<<< HEAD
execute 'Enable Authd' do
  command '/var/ossec/bin/ossec-control enable auth'
  not_if "ps axu | grep ossec-authd | grep -v grep"
  notifies :restart, "service[wazuh]", :delayed
end

=======
# The dependences should be installed only when the cluster is enabled
if node['ossec']['conf']['server']['cluster']['disabled'] == 'no'
 case node['platform']
  when 'debian', 'ubuntu'
    log 'Wazuh_Cluster_not_compatible' do
      message "Wazuh cluster is not compatible with this version with #{node['platform']}"
      level :warn
    end
  when 'redhat', 'centos'
    if node['platform_version'].to_i == 7
      package ['python-setuptools', 'python-cryptography']
    end
  end
end

# Auth need to be enable only in master node.
if node['ossec']['conf']['server']['cluster']['node_type'] == 'master'
  execute 'Enable Authd' do
    command '/var/ossec/bin/ossec-control enable auth'
    not_if "ps axu | grep ossec-authd | grep -v grep"
    notifies :restart, "service[wazuh]", :delayed
  end
end
>>>>>>> d3e691bba7f9a6a500c6722eb8e57a4110600cbb
include_recipe 'wazuh_ossec::common'

include_recipe 'wazuh_ossec::wazuh_api'

bash 'Creating ossec-authd key and cert' do
  code <<-EOH
    openssl genrsa -out #{node['ossec']['dir']}/etc/sslmanager.key 4096 &&
    openssl req -new -x509 -key #{node['ossec']['dir']}/etc/sslmanager.key\
   -out #{node['ossec']['dir']}/etc/sslmanager.cert -days 3650\
   -subj /CN=fqdn/
    EOH
  not_if { ::File.exist?("#{node['ossec']['dir']}/etc/sslmanager.cert") }
end

template "#{node['ossec']['dir']}/etc/local_internal_options.conf" do
  source 'var/ossec/etc/manager_local_internal_options.conf'
  owner 'root'
  group 'ossec'
  action :create
  notifies :restart, 'service[wazuh]', :delayed
end

template "#{node['ossec']['dir']}/etc/rules/local_rules.xml" do
  source 'ossec_local_rules.xml.erb'
  owner 'root'
  group 'ossec'
  mode '0640'
  notifies :restart, 'service[wazuh]', :delayed
end


template "#{node['ossec']['dir']}/etc/decoders/local_decoder.xml" do
  source 'ossec_local_decoder.xml.erb'
  owner 'root'
  group 'ossec'
  mode '0640'
  notifies :restart, 'service[wazuh]', :delayed
end

service 'wazuh' do
  service_name 'wazuh-manager'
  supports status: true, restart: true
  action [:enable, :start]
end