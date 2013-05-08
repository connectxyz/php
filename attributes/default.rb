#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Cookbook Name:: php
# Attribute:: default
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
case node[:platform]
when "debian","ubuntu" # debian/ubuntu use lib for 32 and 64bit
    lib_dir = 'lib'
else
    lib_dir = kernel['machine'] =~ /x86_64/ ? 'lib64' : 'lib'
end

default['php']['install_method'] = 'package'
default['php']['directives'] = {}

case node["platform_family"]
when "rhel", "fedora"
  default['php']['conf_dir']      = '/etc'
  default['php']['ext_conf_dir']  = '/etc/php.d'
  default['php']['fpm_user']      = 'nobody'
  default['php']['fpm_group']     = 'nobody'
  default['php']['ext_dir']       = "/usr/#{lib_dir}/php/modules"
  if node['platform_version'].to_f < 6 then
    default['php']['packages'] = ['php53', 'php53-devel', 'php53-cli', 'php-pear']
  else
    default['php']['packages'] = ['php', 'php-devel', 'php-cli', 'php-pear']
  end
when "debian"
  default['php']['conf_dir']      = '/etc/php5/cli'
  default['php']['ext_conf_dir']  = '/etc/php5/conf.d'
  default['php']['fpm_user']      = 'www-data'
  default['php']['fpm_group']     = 'www-data'
  default['php']['packages']      = ['php5-cgi', 'php5', 'php5-dev', 'php5-cli', 'php-pear']
when "suse"
  default['php']['conf_dir']      = '/etc/php5/cli'
  default['php']['ext_conf_dir']  = '/etc/php5/conf.d'
  default['php']['fpm_user']      = 'wwwrun'
  default['php']['fpm_group']     = 'www'
  default['php']['packages']      = ['apache2-mod_php5', 'php5-pear']
else
  default['php']['conf_dir']      = '/etc/php5/cli'
  default['php']['ext_conf_dir']  = '/etc/php5/conf.d'
  default['php']['fpm_user']      = 'www-data'
  default['php']['fpm_group']     = 'www-data'
  default['php']['packages']      = ['php5-cgi', 'php5', 'php5-dev', 'php5-cli', 'php-pear']
end

default['php']['url'] = 'http://us.php.net/distributions'
default['php']['version'] = '5.3.10'
default['php']['checksum'] = 'ee26ff003eaeaefb649735980d9ef1ffad3ea8c2836e6ad520de598da225eaab'
default['php']['prefix_dir'] = '/usr/local'

default['php']['libcouchbase_prefix_dir'] = '/usr/local'

default['php']['configure_options'] = %W{--prefix=#{php['prefix_dir']}
                                          --with-libdir=#{lib_dir}
                                          --with-config-file-path=#{php['conf_dir']}
                                          --with-config-file-scan-dir=#{php['ext_conf_dir']}
                                          --with-pear
                                          --enable-fpm
                                          --with-fpm-user=#{php['fpm_user']}
                                          --with-fpm-group=#{php['fpm_group']}
                                          --with-zlib
                                          --with-openssl
                                          --with-kerberos
                                          --with-bz2
                                          --with-curl
                                          --enable-ftp
                                          --enable-zip
                                          --enable-exif
                                          --with-gd
                                          --enable-gd-native-ttf
                                          --with-gettext
                                          --with-gmp
                                          --with-mhash
                                          --with-iconv
                                          --with-imap
                                          --with-imap-ssl
                                          --enable-sockets
                                          --enable-soap
                                          --with-xmlrpc
                                          --with-libevent-dir
                                          --with-mcrypt
                                          --enable-mbstring
                                          --with-t1lib
                                          --with-mysql
                                          --with-mysqli=/usr/bin/mysql_config
                                          --with-mysql-sock
                                          --with-sqlite3
                                          --with-pdo-mysql
                                          --with-pdo-sqlite}
