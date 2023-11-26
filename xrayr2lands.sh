#!/binstall

# 控制台字体
red() {
	echo -e "\033[31m\033[01m$1\033[0m"
}

green() {
	echo -e "\033[32m\033[01m$1\033[0m"
}

yellow() {
	echo -e "\033[33m\033[01m$1\033[0m"
}

# 判断系统及定义系统安装依赖方式
REGEX=("debian" "ubuntu" "centos|red hat|kernel|oracle linux|alma|rocky" "'amazon linux'")
RELEASE=("Debian" "Ubuntu" "CentOS" "CentOS" "Alpine")
PACKAGE_UPDATE=("apt -y update" "apt -y update" "yum -y update" "yum -y update")
PACKAGE_INSTALL=("apt -y install" "apt -y install" "yum -y install" "yum -y install" "apk add -f")
PACKAGE_REMOVE=("apt -y remove" "apt -y remove" "yum -y remove" "yum -y remove")

CMD=("$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)" "$(hostnamectl 2>/dev/null | grep -i system | cut -d : -f2)" "$(lsb_release -sd 2>/dev/null)" "$(grep -i description /etc/lsb-release 2>/dev/null | cut -d \" -f2)" "$(grep . /etc/redhat-release 2>/dev/null)" "$(grep . /etc/issue 2>/dev/null | cut -d \\ -f1 | sed '/^[ ]*$/d')")

for i in "${CMD[@]}"; do
	SYS="$i" && [[ -n $SYS ]] && break
done

for ((int = 0; int < ${#REGEX[@]}; int++)); do
	[[ $(echo "$SYS" | tr '[:upper:]' '[:lower:]') =~ ${REGEX[int]} ]] && SYSTEM="${RELEASE[int]}" && [[ -n $SYSTEM ]] && break
done

[[ -z $SYSTEM ]] && red "不支持VPS的当前系统，请使用主流的操作系统" && exit 1

archAffix() {
	case "$(uname -m)" in
  x86_64 | x64 | amd64) return 0 ;;
	aarch64 | arm64) return 0 ;;
	*) red "不支持的CPU架构，脚本即将退出！" ;;
	esac

	return 0
}

install() {
	install_XrayR
	clear
	makeConfig
}

install_XrayR() {
	[[ -z $(type -P curl) ]] && ${PACKAGE_UPDATE[int]} && ${PACKAGE_INSTALL[int]} curl
	[[ -z $(type -P socat) ]] && ${PACKAGE_UPDATE[int]} && ${PACKAGE_INSTALL[int]} socat
	wget --no-check-certificate -O Aiko-Server.sh https://raw.githubusercontent.com/AikoPanel/Aiko-Server-Script/master/install.sh && bash Aiko-Server.sh
}

makeConfig() {
  echo "---------------"
	read -p "Nhập Subdomain của bạn :" subDomain
	echo "---------------"
	# read -p "Nhập link website ( https://2lands.me ) :" airWebsite
 	# echo "---------------"
	# read -p "Nhập type website :" airWebsitetype
	# echo "---------------"
	read -p "Số node ID 80 :" makeNodeID
	echo "---------------"
    read -p "Nhập type node 80 (Vless: 0, Vmess: 1, Trojan: 2, Shadowsocks: 3, Shadowsocks-Plugin: 4) :" type80
    echo "---------------"
    read -p "Số node ID 443 :" makeNodeID443
	echo "---------------"
    read -p "Nhập type node 443 (Vless: 0, Vmess: 1, Trojan: 2, Shadowsocks: 3, Shadowsocks-Plugin: 4) :" type443
    echo "---------------"
	rm -f /etc/Aiko-Server/aiko.yml
	if [[ -z $(~/.acme.sh/acme.sh -v 2>/dev/null) ]]; then
		curl https://get.acme.sh | sh -s email=script@github.com
		source ~/.bashrc
		bash ~/.acme.sh/acme.sh --upgrade --auto-upgrade
	fi
         cat <<EOF >/etc/Aiko-Server/aiko.yml
Log:
  Level: warning # Log level: none, error, warning, info, debug 
  AccessPath: # /etc/Aiko-Server/access.Log
  ErrorPath: # /etc/Aiko-Server/error.log
DnsConfigPath: # /etc/Aiko-Server/dns.json # Path to dns config, check https://xtls.github.io/config/dns.html for help
RouteConfigPath: # /etc/Aiko-Server/route.json # Path to route config, check https://xtls.github.io/config/routing.html for help
InboundConfigPath: # /etc/Aiko-Server/custom_inbound.json # Path to custom inbound config, check https://xtls.github.io/config/inbound.html for help
OutboundConfigPath: # /etc/Aiko-Server/custom_outbound.json # Path to custom outbound config, check https://xtls.github.io/config/outbound.html for help
Nodes:
  -
    PanelType: "AikoPanel" # Panel type: SSpanel, V2board, PMpanel, Proxypanel, V2RaySocks
    ApiConfig:
      ApiHost: "https://texpn.node-01-run-api.online"
      ApiKey: "duongdinhtai2004"
      NodeID: $makeNodeID
      NodeType: $type80 # Node type: V2ray, Shadowsocks, Trojan, Shadowsocks-Plugin
      Timeout: 30 # Timeout for the api request
      EnableVless: false # Enable Vless for V2ray Type
      EnableXTLS: false # Enable XTLS for V2ray and Trojan
      SpeedLimit: 0 # Mbps, Local settings will replace remote settings, 0 means disable
      DeviceLimit: 0 # Local settings will replace remote settings, 0 means disable
      RuleListPath: # /etc/AikoR/rulelist Path to local rulelist file
    ControllerConfig:
      ListenIP: 0.0.0.0 # IP address you want to listen
      SendIP: 0.0.0.0 # IP address you want to send pacakage
      UpdatePeriodic: 60 # Time to update the nodeinfo, how many sec.
      EnableDNS: false # Use custom DNS config, Please ensure that you set the dns.json well
      DNSType: AsIs # AsIs, UseIP, UseIPv4, UseIPv6, DNS strategy
      EnableProxyProtocol: false # Only works for WebSocket and TCP
      DisableSniffing: true # Disable sniffing
      DynamicSpeedConfig:
        Limit: 500 # Warned speed. Set to 0 to disable AutoSpeedLimit (mbps)
        WarnTimes: 3 # After (WarnTimes) consecutive warnings, the user will be limited. Set to 0 to punish overspeed user immediately.
        LimitSpeed: 1 # The speedlimit of a limited user (unit: mbps)
        LimitDuration: 60 # How many minutes will the limiting last (unit: minute)
      RedisConfig:
        Enable: false # Enable the Redis limit of a user
        RedisAddr: 0 # The redis server address format: (IP:Port)
        RedisPassword: PASSWORD # Redis password
        RedisDB: 0 # Redis DB (Redis database number, default 0, no need to change)
        Timeout: 5 # Timeout for Redis request
        Expiry: 60 # Expiry time ( Cache time of online IP, unit: second )
      EnableFallback: false # Only support for Trojan and Vless
      FallBackConfigs:  # Support multiple fallbacks
        - SNI: # TLS SNI(Server Name Indication), Empty for any
          Alpn: # Alpn, Empty for any
          Path: # HTTP PATH, Empty for any
          Dest: 80 # Required, Destination of fallback, check https://xtls.github.io/config/features/fallback.html for details.
          ProxyProtocolVer: 0 # Send PROXY protocol version, 0 for disable
      EnableREALITY: false # Enable REALITY
      REALITYConfigs:
        Show: false # Show REALITY debug
        Dest: www.smzdm.com:443 # Required, Same as fallback
        ProxyProtocolVer: 0 # Send PROXY protocol version, 0 for disable
        ServerNames: # Required, list of available serverNames for the client, * wildcard is not supported at the moment.
          - www.smzdm.com
        PrivateKey: YOUR_PRIVATE_KEY # Required, execute './xray x25519' to generate.
        MinClientVer: # Optional, minimum version of Xray client, format is x.y.z.
        MaxClientVer: # Optional, maximum version of Xray client, format is x.y.z.
        MaxTimeDiff: 0 # Optional, maximum allowed time difference, unit is in milliseconds.
        ShortIds: # Required, list of available shortIds for the client, can be used to differentiate between different clients.
          - ""
          - 0123456789abcdef
      CertConfig:
        CertMode: file # Option about how to get certificate: none, file, http, tls, dns. Choose "none" will forcedly disable the tls config.
        CertDomain: "$subDomain" # Domain to cert
        CertFile: /etc/Aiko-Server/cert/aiko_server.cert # Provided if the CertMode is file
        KeyFile: /etc/Aiko-Server/cert/aiko_server.key
        Provider: cloudflare # DNS cert provider, Get the full support list here: https://go-acme.github.io/lego/dns/
        Email: test@me.com
        DNSEnv: # DNS ENV option used by DNS provider
          CLOUDFLARE_EMAIL: dtai45412@gmail.com
          CLOUDFLARE_API_KEY: 7f63bf3bcaa7a6759b9b2160cddba6723495f
  -
    PanelType: "AikoPanel" # Panel type: SSpanel, V2board, PMpanel, Proxypanel, V2RaySocks
    ApiConfig:
      ApiHost: "https://texpn.node-01-run-api.online"
      ApiKey: "duongdinhtai2004"
      NodeID: $makeNodeID443
      NodeType: $type443 # Node type: V2ray, Shadowsocks, Trojan, Shadowsocks-Plugin
      Timeout: 30 # Timeout for the api request
      EnableVless: false # Enable Vless for V2ray Type
      EnableXTLS: false # Enable XTLS for V2ray and Trojan
      SpeedLimit: 0 # Mbps, Local settings will replace remote settings, 0 means disable
      DeviceLimit: 0 # Local settings will replace remote settings, 0 means disable
      RuleListPath: # /etc/AikoR/rulelist Path to local rulelist file
    ControllerConfig:
      ListenIP: 0.0.0.0 # IP address you want to listen
      SendIP: 0.0.0.0 # IP address you want to send pacakage
      UpdatePeriodic: 60 # Time to update the nodeinfo, how many sec.
      EnableDNS: false # Use custom DNS config, Please ensure that you set the dns.json well
      DNSType: AsIs # AsIs, UseIP, UseIPv4, UseIPv6, DNS strategy
      EnableProxyProtocol: false # Only works for WebSocket and TCP
      DisableSniffing: true # Disable sniffing
      DynamicSpeedConfig:
        Limit: 500 # Warned speed. Set to 0 to disable AutoSpeedLimit (mbps)
        WarnTimes: 3 # After (WarnTimes) consecutive warnings, the user will be limited. Set to 0 to punish overspeed user immediately.
        LimitSpeed: 1 # The speedlimit of a limited user (unit: mbps)
        LimitDuration: 60 # How many minutes will the limiting last (unit: minute)
      RedisConfig:
        Enable: false # Enable the Redis limit of a user
        RedisAddr: 0 # The redis server address format: (IP:Port)
        RedisPassword: PASSWORD # Redis password
        RedisDB: 0 # Redis DB (Redis database number, default 0, no need to change)
        Timeout: 5 # Timeout for Redis request
        Expiry: 60 # Expiry time ( Cache time of online IP, unit: second )
      EnableFallback: false # Only support for Trojan and Vless
      FallBackConfigs:  # Support multiple fallbacks
        - SNI: # TLS SNI(Server Name Indication), Empty for any
          Alpn: # Alpn, Empty for any
          Path: # HTTP PATH, Empty for any
          Dest: 443 # Required, Destination of fallback, check https://xtls.github.io/config/features/fallback.html for details.
          ProxyProtocolVer: 0 # Send PROXY protocol version, 0 for disable
      EnableREALITY: false # Enable REALITY
      REALITYConfigs:
        Show: false # Show REALITY debug
        Dest: www.smzdm.com:443 # Required, Same as fallback
        ProxyProtocolVer: 0 # Send PROXY protocol version, 0 for disable
        ServerNames: # Required, list of available serverNames for the client, * wildcard is not supported at the moment.
          - www.smzdm.com
        PrivateKey: YOUR_PRIVATE_KEY # Required, execute './xray x25519' to generate.
        MinClientVer: # Optional, minimum version of Xray client, format is x.y.z.
        MaxClientVer: # Optional, maximum version of Xray client, format is x.y.z.
        MaxTimeDiff: 0 # Optional, maximum allowed time difference, unit is in milliseconds.
        ShortIds: # Required, list of available shortIds for the client, can be used to differentiate between different clients.
          - ""
          - 0123456789abcdef
      CertConfig:
        CertMode: file # Option about how to get certificate: none, file, http, tls, dns. Choose "none" will forcedly disable the tls config.
        CertDomain: "$subDomain" # Domain to cert
        CertFile: /etc/Aiko-Server/cert/aiko_server.cert # Provided if the CertMode is file
        KeyFile: /etc/Aiko-Server/cert/aiko_server.key
        Provider: cloudflare # DNS cert provider, Get the full support list here: https://go-acme.github.io/lego/dns/
        Email: test@me.com
        DNSEnv: # DNS ENV option used by DNS provider
          CLOUDFLARE_EMAIL: dtai45412@gmail.com
          CLOUDFLARE_API_KEY: 7f63bf3bcaa7a6759b9b2160cddba6723495f
EOF
rm -rf /etc/systemd/system/multi-user.target.wants/AikoR.service # Thêm dòng này để xóa thư mục /etc/AikoR
	xrayr restart
	green "Đã cài đặt và cập nhật XrayR với bảng điều khiển thành công！"
	exit 1
}

install
