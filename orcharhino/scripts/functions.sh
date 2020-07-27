# create_answers-yaml(installation_method)
function create_answers_yaml() {
  mkdir -p /etc/orcharhino-installer
  cat >/etc/orcharhino-installer/answers.yaml <<EOL
# The email where the orcharhino admin can be reached:
or_admin_email: ${OR_ADMIN_EMAIL}
# The password for the orcharhino's "admin" account:
or_admin_password: ${OR_ADMIN_PASSWORD}
# The default organization (should not include spaces or special characters):
or_organization: ${OR_ORGANIZATION}
# The default location (should not include spaces or special characters):
or_location: ${OR_LOCATION}
or_dhcp_enabled: false
or_dns_enabled: false
or_tftp_enabled: ${OR_ENABLE_TFTP}
EOL
  cat >>/etc/orcharhino-installer/answers.yaml <<EOL
or_operating_systems:
  - 'Ubuntu18LTS'
  - 'Ubuntu20LTS'
EOL
  if is_oracle || [ $1 == "full" ]; then
    cat >>/etc/orcharhino-installer/answers.yaml <<EOL
  - 'Oracle7'
  - 'Oracle8'
EOL
  fi 
  if is_centos || [ $1 == "full" ]; then
    cat >>/etc/orcharhino-installer/answers.yaml <<EOL
  - 'CentOS7'
  - 'CentOS8'
EOL
  fi 
  if is_rhel || [ $1 == "full" ]; then
    # no OS online medium to configure
    /bin/true
  fi
  if [ $1 == "full" ]; then
    cat >>/etc/orcharhino-installer/answers.yaml <<EOL
  - 'SLES12SP5'
  - 'SLES15SP2'
EOL
  fi
  cat >>/etc/orcharhino-installer/answers.yaml <<EOL
or_operating_system_clients:
  - 'Ubuntu18LTS'
  - 'Ubuntu20LTS'
EOL
  if is_oracle || [ $1 == "full" ]; then
    cat >>/etc/orcharhino-installer/answers.yaml <<EOL
  - 'Oracle7'
  - 'Oracle8'
EOL
  fi 
  if is_centos || [ $1 == "full" ]; then
    cat >>/etc/orcharhino-installer/answers.yaml <<EOL
  - 'CentOS7'
  - 'CentOS8'
EOL
  fi 
  if is_rhel || [ $1 == "full" ]; then
    cat >>/etc/orcharhino-installer/answers.yaml <<EOL
  - 'RHEL7'
  - 'RHEL8'
EOL
  fi
  if [ $1 == "full" ]; then
    cat >>/etc/orcharhino-installer/answers.yaml <<EOL
  - 'SLES12SP5'
  - 'SLES15SP2'
EOL
  fi
  cat >>/etc/orcharhino-installer/answers.yaml <<EOL
or_config_management_systems:
  - 'puppet'
  - 'ansible'
EOL
  if [ $1 == "full" ]; then
    cat >>/etc/orcharhino-installer/answers.yaml <<EOL
  - 'salt'
EOL
  fi
  cat >>/etc/orcharhino-installer/answers.yaml <<EOL
or_compute_resource_providers:
  - 'libvirt'
  - 'ovirt'
  - 'vmware'
or_plugins:
  - 'openscap'
EOL
  if [ $1 == "full" ]; then
    cat >>/etc/orcharhino-installer/answers.yaml <<EOL
  - 'bootdisk'
  - 'dhcp_browser'
  - 'discovery'
  - 'scc_manager'
  - 'snapshot_management'
  - 'virt_who_configure'
  - 'fog_proxmox'
EOL
  fi
  cat >>/etc/orcharhino-installer/answers.yaml <<EOL
or_sec_int_net:
  - "$(get_ip_net)"
EOL
  if [ -z "${proxy['host']}" ]; then
    echo or_http_proxy_enabled: false >> /etc/orcharhino-installer/answers.yaml
  else
    case $(vercomp $or_version 5.4) in
      '<')
        # orcharhino < 5.4
	    cat >>/etc/orcharhino-installer/answers.yaml <<EOL
or_http_proxy_enabled: true
or_http_proxy_url: "${proxy['scheme']}://${proxy['host']}"
or_http_proxy_port: "${proxy['port']}"
or_http_proxy_username: "${proxy['user']}"
or_http_proxy_password: "${proxy['pass']}"
EOL
        ;;
      '>'|'==')
        # orcharhino >= 5.4
        cat >>/etc/orcharhino-installer/answers.yaml <<EOL
or_http_proxy_enabled: true
or_http_proxy_scheme: "${proxy['scheme']}" 
or_http_proxy_host: "${proxy['host']}"
or_http_proxy_port: "${proxy['port']}"
or_http_proxy_username: "${proxy['user']}"
or_http_proxy_password: "${proxy['pass']}"
EOL
        ;; 
    esac
  fi
}

function print_answers_yaml() {
    if [ -e /etc/orcharhino-installer/answers.yaml ]; then
      echo using answers.yaml:
      cat /etc/orcharhino-installer/answers.yaml
    else
      echo empty answers.yaml
    fi
}

function extract_proxy() {
  proto="$(echo $1 | grep :// | sed -e's,^\(.*://\).*,\1,g')"
  # remove the protocol
  url="$(echo ${1/$proto/})"
  scheme=$(echo $proto | sed -e's,://,,')
  # extract the user (if any)
  userpass="$(echo $url | grep @ | cut -d@ -f1)"
  pass="$(echo $userpass | grep : | cut -d: -f2)"
  if [ -n "$pass" ]; then
    user="$(echo $userpass | grep : | cut -d: -f1)"
  else
    user=$userpass
  fi

  # extract the host
  host="$(echo ${url/$user@/} | cut -d/ -f1)"
  # by request - try to extract the port
  port="$(echo $host | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')"
  host=$(echo $host | sed -e's/\(.*\):.*/\1/')

  proxy['url']=$url
  proxy['proto']=$proto
  proxy['scheme']=$scheme
  proxy['user']=$user
  proxy['pass']=$pass
  proxy['host']=$host
  proxy['port']=$port
  proxy['path']=$path
}

function vercomp () {
if [[ $1 == $2 ]]
  then
    echo '=='
    return 0
  fi
  local IFS=.
  local i ver1=($1) ver2=($2)
  # fill empty fields in ver1 with zeros
  for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
    ver1[i]=0
  done
  for ((i=0; i<${#ver1[@]}; i++)); do
    if [[ -z ${ver2[i]} ]]; then
      # fill empty fields in ver2 with zeros
      ver2[i]=0
    fi
    if ((10#${ver1[i]} > 10#${ver2[i]})); then
      echo '>'
      return 0
    fi
    if ((10#${ver1[i]} < 10#${ver2[i]})); then
      echo '<'
      return 0
    fi
done
echo '=='
return 0
}

function set_proxy_cmd_options() {
  if [ -n "${proxy['host']}" ]; then
    case $(vercomp $installer_version 2.2.0) in
      '<')
      # orcharhino < 5.4
      echo "Installer is for orcharhino < 5.4"
      cmd_proxy_options="--http-proxy-url="${proxy[host]}" --http-proxy-port="${proxy[port]}""
      ;;
      '>'|'==')
      # orcharhino >= 5.4
      echo "Installer is for orcharhino >= 5.4"
      cmd_proxy_options="--http-proxy-host="${proxy[host]}" --http-proxy-port="${proxy[port]}" --http-proxy-scheme="${proxy['scheme']}""
      ;;
    esac
    if [ -n "${proxy[user]}" ]; then
      cmd_proxy_options="--http-proxy-user="${proxy[user]}" --http-proxy-passwd="${proxy[pass]}" $cmd_proxy_options"
    fi
  fi
}

function get_latest_or_version() {
  python /opt/orcharhino/maintain/repo_map/repolist.py --list 2>&1 | head -1
}

function get_os() {
  if [ -e /etc/oracle-release ]; then
    echo oracle
  elif [ -e /etc/centos-release ]; then
    echo centos
  elif [ -e /etc/redhat-release ]; then
    echo rhel
  else
    echo unknown
  fi
}

function is_oracle {
  if [ $(get_os) == "oracle" ]; then
    return 0
  fi
  return 1
}

function is_centos {
  if [ $(get_os) == "centos" ]; then
    return 0
  fi
  return 1
}

function is_rhel {
  if [ $(get_os) == "rhel" ]; then
    return 0
  fi
  return 1
}

function get_ip_net {
  ip a | grep inet | grep -v 127.0.0.1 | head -1 | awk '{print $2}'
}

