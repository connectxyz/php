if Chef::Config[:solo]
  Chef::Log.warn("This recipe uses search. Chef Solo does not support search.")
end

#
#
# Author::  Seth Chisamore (<schisamo@opscode.com>)
# Cookbook Name:: php
# Recipe:: package
#
# Copyright 2011, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


begin
  memcacheserver = search(:node, "role:Couchbase_Server").map {|n| n["network"]["interfaces"][node['network_interfaces']['private']]["addresses"].select { |address, data| data["family"] == "inet" }.keys}.flatten.compact
rescue
  log "no memcache or couchbase servers available in search!" do
    level :warn
  end
  memcacheserver = []
end

package "git"

configure_options = node['php']['configure_options']

include_recipe "build-essential"
include_recipe "xml"
include_recipe "mysql::client" if configure_options =~ /mysql/

pkgs = value_for_platform(
    ["centos","redhat","fedora", "scientific"] =>
        {"default" => %w{ bzip2-devel libc-client-devel curl-devel freetype-devel gmp-devel libjpeg-devel krb5-devel libmcrypt-devel libpng-devel openssl-devel t1lib-devel mhash-devel }},
    [ "debian", "ubuntu" ] =>
        {"default" => %w{ libmemcached-dev libyaml-dev libyaml-0-2 libbz2-dev libc-client2007e-dev libcurl4-gnutls-dev libfreetype6-dev libgmp3-dev libjpeg62-dev libkrb5-dev libmcrypt-dev libpng12-dev libssl-dev libt1-dev libtool libev-dev re2c unzip openjdk-7-jdk }},
    "default" => %w{ libmemcached-dev libyaml-dev libyaml-0-2 libbz2-dev libc-client2007e-dev libcurl4-gnutls-dev libfreetype6-dev libgmp3-dev libjpeg62-dev libkrb5-dev libmcrypt-dev libpng12-dev libssl-dev libt1-dev libev-dev re2c unzip openjdk-7-jdk }
)

pkgs.each do |pkg|
  package pkg do
    action :install
  end
end

#version = node['php']['version']

#remote_file "#{Chef::Config[:file_cache_path]}/php-#{version}.tar.gz" do
#  source "#{node['php']['url']}/php-#{version}.tar.gz"
#  checksum node['php']['checksum']
#  mode "0644"
#  not_if "which php"
#end

git "#{Chef::Config[:file_cache_path]}/php-src" do
  repository "https://github.com/php/php-src.git"
  reference node['php']['source_branch']
  action :sync
end


git "#{Chef::Config[:file_cache_path]}/phpcouchbase" do
  repository "git://github.com/couchbase/php-ext-couchbase.git"
  reference 'master'
  action :sync
end

git "#{Chef::Config[:file_cache_path]}/libcouchbase" do
  repository "git://github.com/couchbase/libcouchbase.git"
  reference 'master'
  action :sync
end


=begin


###   git phpcouchbase is broken. This is a quick fix
###   #include <libcouchbase/couchebase.h> needs to be changed to #include "libcouchbase/couchebase.h"
ruby_block 'replace-internal-include' do
  block do
    text = File.read("#{Chef::Config[:file_cache_path]}/phpcouchbase/internal.h")
    replace = text.gsub(/\<libcouchbase\/couchbase.h\>/, "\"libcouchbase\/couchbase.h\"")
    File.open("#{Chef::Config[:file_cache_path]}/phpcouchbase/internal.h", "w") {|file| file.puts replace}
  end
end

=end



link "/usr/src/php" do
  to "#{Chef::Config[:file_cache_path]}/php-src"
end

link "/usr/src/phpcouchbase" do
  to "#{Chef::Config[:file_cache_path]}/phpcouchbase"
end

link "/usr/src/libcouchbase" do
  to "#{Chef::Config[:file_cache_path]}/libcouchbase"
end

bash "build php" do
  cwd "#{Chef::Config[:file_cache_path]}/php-src"
  code <<-EOF
    (./buildconf --force)
    (./configure #{node['php']['configure_options']})
    (make && make install)
  EOF
  only_if { node['php']['build'] }
end

bash "install libcouchbase" do
  cwd "#{Chef::Config[:file_cache_path]}/libcouchbase"
  code <<-EOF
    (config/autorun.sh)
    (./configure --prefix=/usr/local/libcouchbase --disable-couchbasemock)
    (make && make install)
  EOF
  only_if { node['php']['build'] }
end

bash "build couchbase" do
  cwd "#{Chef::Config[:file_cache_path]}/phpcouchbase"
  code <<-EOF
    (/usr/local/php/bin/phpize)
    (./configure CPPFLAGS='-I/usr/local/libcouchbase/include' LDFLAGS='-L/usr/local/libcouchbase/lib' --prefix=/usr/local/phpcouchbase --with-couchbase=/usr/local/libcouchbase --with-php-config=/usr/local/php/bin/php-config)
    (make && make install)
  EOF
  only_if { node['php']['build'] }
end

directory node['php']['conf_dir'] do
  owner "root"
  group "root"
  mode "0755"
  recursive true
end

directory node['php']['ext_conf_dir'] do
  owner "root"
  group "root"
  mode "0755"
  recursive true
end

template "#{node['php']['conf_dir']}/php.ini" do
  source "php.cxyz.ini.erb"
  variables(
      :memcacheserver => memcacheserver
  )
  owner "root"
  group "root"
  mode "0644"
end

=begin
php_pear "memcache" do
  action :install
end

php_pear "yaml" do
  action :install
end
=end
