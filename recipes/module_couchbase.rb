#
# Author::  Paige Thompson (<paige@connectxyz.com>)

if node['php']['install_method'] != 'source'
  Chef::Application.fatal!("this module requires PHP to be compiled from source?")
  #TODO
  #I don't remember why... I'm not sure if there's good support in package clients for
  #couchbase 2 or something? then again 12.04 we require PHP-5.4 for this to work and
  # for several other reasons.
end

include_recipe "php::#{node['php']['install_method']}"

pkgs = value_for_platform(
    ["centos","redhat","fedora", "scientific"] =>
        {"default" => %w{#TODO }},
    [ "debian", "ubuntu" ] =>
        {"default" => %w{ libev-dev re2c unzip openjdk-7-jdk }},
    "default" => %w{ libev-dev re2c unzip openjdk-7-jdk }
)

pkgs.each do |pkg|
  package pkg do
    action :install
  end
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

link "/usr/src/phpcouchbase" do
  to "#{Chef::Config[:file_cache_path]}/phpcouchbase"
end

link "/usr/src/libcouchbase" do
  to "#{Chef::Config[:file_cache_path]}/libcouchbase"
end

bash "compile_libcouchbase" do
  cwd "#{Chef::Config[:file_cache_path]}/libcouchbase"
  code <<-EOF
    (config/autorun.sh)
    (./configure --prefix=#{node['php']['libcouchbase_prefix_dir']} --disable-couchbasemock)
    (make && make install)
  EOF
  only_if { node['php']['build_libcouchbase'] }
end

bash "compile_php_couchbase_extension" do
  cwd "#{Chef::Config[:file_cache_path]}/phpcouchbase"
  code <<-EOF
    (/usr/local/php/bin/phpize)
    (./configure CPPFLAGS='-I#{node['php']['libcouchbase_prefix_dir']}/include' LDFLAGS='-L#{node['php']['libcouchbase_prefix_dir']}/lib' --with-couchbase=#{node['php']['libcouchbase_prefix_dir']} --with-php-config=#{node['php']['prefix_dir']}/bin/php-config)
    (make && make install)
  EOF
  only_if { node['php']['build_couchbase_extension'] }
end



#TODO def manage_pecl_ini(name, action, directives, zend_extensions) I want to use the cookbooks built in provider to manage this extension once compiled/installed.
