#!/bin/bash
#
# cpe-builder.sh - CPE (Common Platform Enumeration) name construction
# Builds valid CPE 2.3 URIs from nmap service detection output
#

# CPE Product Mapping Database
# Maps nmap product names to CPE vendor:product format
# Format: ["nmap_product_name"]="vendor:product"
declare -g -A CPE_PRODUCT_MAP=(
    # Web Servers
    ["apache httpd"]="apache:http_server"
    ["apache"]="apache:http_server"
    ["nginx"]="nginx:nginx"
    ["microsoft-iis"]="microsoft:internet_information_services"
    ["lighttpd"]="lighttpd:lighttpd"
    ["litespeed"]="litespeedtech:litespeed_web_server"

    # SSH Servers
    ["openssh"]="openbsd:openssh"
    ["dropbear"]="matt_johnston:dropbear_ssh_server"

    # Databases
    ["mysql"]="mysql:mysql"
    ["mariadb"]="mariadb:mariadb"
    ["postgresql"]="postgresql:postgresql"
    ["mongodb"]="mongodb:mongodb"
    ["redis"]="redis:redis"

    # FTP Servers
    ["vsftpd"]="vsftpd_project:vsftpd"
    ["proftpd"]="proftpd:proftpd"
    ["pureftpd"]="pureftpd:pure-ftpd"

    # DNS Servers
    ["bind"]="isc:bind"
    ["dnsmasq"]="thekelleys:dnsmasq"

    # Mail Servers
    ["postfix"]="postfix:postfix"
    ["sendmail"]="sendmail:sendmail"
    ["exim"]="exim:exim"

    # Other Common Services
    ["samba"]="samba:samba"
    ["docker"]="docker:docker"
    ["kubernetes"]="kubernetes:kubernetes"
    ["tomcat"]="apache:tomcat"
    ["jetty"]="eclipse:jetty"
)

# Normalize product name to CPE vendor:product format
# Args: $1=raw_product_name (e.g., "Apache httpd" or "nginx")
# Returns: vendor:product (e.g., "apache:http_server")
normalize_product_name() {
    local raw_product="$1"

    if [ -z "$raw_product" ]; then
        return 1
    fi

    # Convert to lowercase for matching
    local product_lower=$(echo "$raw_product" | tr '[:upper:]' '[:lower:]')

    # Check if product exists in mapping database
    if [ -n "${CPE_PRODUCT_MAP[$product_lower]}" ]; then
        echo "${CPE_PRODUCT_MAP[$product_lower]}"
        return 0
    fi

    # Fallback: Use product name as both vendor and product
    # Remove spaces, convert to lowercase, sanitize
    local sanitized=$(echo "$product_lower" | sed 's/[^a-z0-9_-]/_/g' | sed 's/__*/_/g')
    echo "${sanitized}:${sanitized}"
    return 0
}

# Normalize version string for CPE
# Args: $1=version_string
# Returns: Normalized version for CPE
normalize_version() {
    local version="$1"

    if [ -z "$version" ]; then
        echo "*"
        return 0
    fi

    # Handle special version indicators
    case "$version" in
        "UNKNOWN"|"unknown"|"*")
            echo "*"
            return 0
            ;;
        "")
            echo "*"
            return 0
            ;;
    esac

    # Remove common suffixes that don't affect CVE matching
    version=$(echo "$version" | sed 's/p[0-9]*$//')  # Remove patch indicators like p1
    version=$(echo "$version" | sed 's/-[a-z]*$//')  # Remove suffixes like -Ubuntu

    # Return cleaned version
    echo "$version"
    return 0
}

# Build full CPE 2.3 string
# Args: $1=product, $2=version, $3=vendor (optional), $4=part (optional, default: a)
# Returns: Full CPE 2.3 URI string
build_cpe_string() {
    local product="$1"
    local version="$2"
    local vendor="${3:-}"
    local part="${4:-a}"  # a=application, o=operating_system, h=hardware

    if [ -z "$product" ]; then
        return 1
    fi

    # Normalize version
    version=$(normalize_version "$version")

    # If vendor not provided, derive from product name
    if [ -z "$vendor" ]; then
        local vendor_product=$(normalize_product_name "$product")
        vendor=$(echo "$vendor_product" | cut -d':' -f1)
        product=$(echo "$vendor_product" | cut -d':' -f2)
    fi

    # Construct CPE 2.3 URI
    # Format: cpe:2.3:part:vendor:product:version:update:edition:language:sw_edition:target_sw:target_hw:other
    # We use wildcards (*) for optional fields
    echo "cpe:2.3:${part}:${vendor}:${product}:${version}:*:*:*:*:*:*:*"
    return 0
}

# Parse nmap service string and build CPE
# Args: $1=product_name, $2=version
# Returns: CPE 2.3 string
build_cpe_from_nmap() {
    local product="$1"
    local version="$2"

    if [ -z "$product" ]; then
        return 1
    fi

    build_cpe_string "$product" "$version"
}

# URL-encode CPE string for API queries
# Args: $1=cpe_string
# Returns: URL-encoded CPE string
urlencode_cpe() {
    local cpe="$1"

    if [ -z "$cpe" ]; then
        return 1
    fi

    # Use python if available for proper URL encoding
    if command -v python3 &>/dev/null; then
        python3 -c "import urllib.parse; print(urllib.parse.quote('$cpe'))"
        return 0
    elif command -v python &>/dev/null; then
        python -c "import urllib; print urllib.quote('$cpe')"
        return 0
    fi

    # Fallback: Basic URL encoding with sed
    echo "$cpe" | sed 's/:/%3A/g' | sed 's/\//%2F/g' | sed 's/ /%20/g'
    return 0
}

# Extract vendor and product from CPE string
# Args: $1=cpe_string
# Returns: vendor:product
extract_vendor_product() {
    local cpe="$1"

    if [ -z "$cpe" ] || [[ ! "$cpe" =~ ^cpe:2\.3: ]]; then
        return 1
    fi

    # CPE format: cpe:2.3:part:vendor:product:version:...
    local vendor=$(echo "$cpe" | cut -d':' -f4)
    local product=$(echo "$cpe" | cut -d':' -f5)

    echo "${vendor}:${product}"
    return 0
}

# Validate CPE 2.3 string format
# Args: $1=cpe_string
# Returns: 0 if valid, 1 if invalid
validate_cpe() {
    local cpe="$1"

    if [ -z "$cpe" ]; then
        return 1
    fi

    # Check if starts with cpe:2.3:
    if [[ ! "$cpe" =~ ^cpe:2\.3: ]]; then
        return 1
    fi

    # Count colons (should have at least 12 for full CPE 2.3)
    local colon_count=$(echo "$cpe" | tr -cd ':' | wc -c)
    if [ "$colon_count" -lt 12 ]; then
        return 1
    fi

    return 0
}

# Add custom product mapping
# Args: $1=nmap_product_name, $2=vendor:product
add_product_mapping() {
    local nmap_product="$1"
    local vendor_product="$2"

    if [ -z "$nmap_product" ] || [ -z "$vendor_product" ]; then
        return 1
    fi

    # Convert to lowercase
    nmap_product=$(echo "$nmap_product" | tr '[:upper:]' '[:lower:]')

    # Add to mapping
    CPE_PRODUCT_MAP["$nmap_product"]="$vendor_product"

    return 0
}

# List all product mappings
list_product_mappings() {
    echo "CPE Product Mappings:"
    echo "===================="
    for key in "${!CPE_PRODUCT_MAP[@]}"; do
        echo "  \"$key\" -> ${CPE_PRODUCT_MAP[$key]}"
    done | sort
}
