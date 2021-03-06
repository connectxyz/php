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

configure_options = node['php']['configure_options'].join(" ")

include_recipe "build-essential"
include_recipe "xml"
include_recipe "mysql::client" if configure_options =~ /mysql/

pkgs = value_for_platform(
    ["centos","redhat","fedora", "scientific"] =>
        {"default" => %w{ bzip2-devel libc-client-devel curl-devel freetype-devel gmp-devel libjpeg-devel krb5-devel libmcrypt-devel libpng-devel openssl-devel t1lib-devel mhash-devel }},
    [ "debian", "ubuntu" ] =>
        {"default" => %w{ libbz2-dev libc-client2007e-dev libcurl4-gnutls-dev libfreetype6-dev libgmp3-dev libjpeg62-dev libkrb5-dev libmcrypt-dev libpng12-dev libssl-dev libt1-dev }},
    "default" => %w{ libbz2-dev libc-client2007e-dev libcurl4-gnutls-dev libfreetype6-dev libgmp3-dev libjpeg62-dev libkrb5-dev libmcrypt-dev libpng12-dev libssl-dev libt1-dev }
)

pkgs.each do |pkg|
  package pkg do
    action :install
  end
end

version = node['php']['version']

if node['php']['use_git']

  git "#{Chef::Config[:file_cache_path]}/php-src" do
    repository node['php']['git_repository_url']
    reference node['php']['git_source_branch']
    action :sync
  end

  link "/usr/src/php" do
    to "#{Chef::Config[:file_cache_path]}/php-src"
  end

  bash "build php" do
    cwd "#{Chef::Config[:file_cache_path]}/php-src"
    code <<-EOF
    (./buildconf --force)
    (./configure #{node['php']['configure_options']})
    (make && make install)
    EOF
    only_if { node['php']['build_php'] }
  end
else

  remote_file "#{Chef::Config[:file_cache_path]}/php-#{version}.tar.gz" do
    source "#{node['php']['url']}/php-#{version}.tar.gz"
    checksum node['php']['checksum']
    mode "0644"
    not_if "which php"
  end

  link "/usr/src/php" do
    to "#{Chef::Config[:file_cache_path]}/php-#{version}"
  end

  bash "build php" do
    cwd Chef::Config[:file_cache_path]
    code <<-EOF
  tar -zxvf php-#{version}.tar.gz
  (cd php-#{version} && ./configure #{configure_options})
  (cd php-#{version} && make && make install)
    EOF
    not_if "which php"
  end
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
  source "php.ini.erb"
  owner "root"
  group "root"
  mode "0644"
end


#TODO only if cgi service is to be enabled, also needs support for bluepill and init.d and bla bla bla

include_recipe "runit"
runit_service "php-fcgi"

service "php-fcgi" do
  supports :status => true, :restart => true, :reload => true
  reload_command "#{node['runit']['sv_bin']} hup #{node['runit']['service_dir']}/php-fcgi"
end

