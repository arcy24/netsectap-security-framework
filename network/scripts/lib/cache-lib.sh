#!/bin/bash
#
# cache-lib.sh - Caching utilities for CVE lookup
# Provides file-based caching to minimize API calls and improve performance
#

# Get script directory for relative paths
CACHE_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_PROJECT_ROOT="$(dirname "$(dirname "$CACHE_LIB_DIR")")"

# Load configuration if available
CACHE_CONFIG_FILE="$CACHE_PROJECT_ROOT/config/cve-config.conf"
if [ -f "$CACHE_CONFIG_FILE" ]; then
    source "$CACHE_CONFIG_FILE"
fi

# Default values if not set in config
CACHE_DIR="${CACHE_DIR:-$CACHE_PROJECT_ROOT/cache/cve}"
CACHE_TTL_HOURS="${CACHE_TTL_HOURS:-168}"  # 7 days default
CACHE_MAX_SIZE_MB="${CACHE_MAX_SIZE_MB:-100}"
CACHE_AUTO_PRUNE="${CACHE_AUTO_PRUNE:-true}"

# Initialize cache directory structure
init_cache() {
    if [ ! -d "$CACHE_DIR" ]; then
        mkdir -p "$CACHE_DIR" 2>/dev/null || {
            echo "[ERROR] Failed to create cache directory: $CACHE_DIR" >&2
            return 1
        }
    fi

    # Create metadata file if it doesn't exist
    local metadata_file="$CACHE_DIR/metadata.txt"
    if [ ! -f "$metadata_file" ]; then
        cat > "$metadata_file" << EOF
# CVE Cache Metadata
# Created: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
# TTL: ${CACHE_TTL_HOURS} hours
# Max Size: ${CACHE_MAX_SIZE_MB} MB
EOF
    fi

    # Auto-prune if enabled
    if [ "$CACHE_AUTO_PRUNE" = true ]; then
        prune_cache 30 2>/dev/null  # Prune entries older than 30 days
    fi

    return 0
}

# Generate cache key from product and version
# Args: $1=product, $2=version
# Returns: sanitized cache key
generate_cache_key() {
    local product="$1"
    local version="$2"

    if [ -z "$product" ] || [ -z "$version" ]; then
        echo "" >&2
        return 1
    fi

    # Sanitize: lowercase, replace spaces/special chars with underscores
    local key=$(echo "${product}_${version}" | \
                tr '[:upper:]' '[:lower:]' | \
                sed 's/[^a-z0-9_.]/_/g' | \
                sed 's/__*/_/g')  # Remove duplicate underscores

    echo "${key}.json"
}

# Check if cached CVE data exists and is fresh
# Args: $1=cache_key (e.g., "apache_2.4.49.json"), $2=max_age_hours (optional, default: CACHE_TTL_HOURS)
# Returns: 0 if valid cache exists, 1 otherwise
check_cache() {
    local cache_key="$1"
    local max_age_hours="${2:-$CACHE_TTL_HOURS}"

    if [ -z "$cache_key" ]; then
        return 1  # No cache key provided
    fi

    local cache_file="$CACHE_DIR/$cache_key"

    # Check if file exists
    if [ ! -f "$cache_file" ]; then
        return 1  # Cache miss
    fi

    # Check age
    if [ -n "$max_age_hours" ] && [ "$max_age_hours" -gt 0 ]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
        local max_age=$((max_age_hours * 3600))

        if [ $cache_age -gt $max_age ]; then
            return 1  # Cache stale
        fi
    fi

    # Verify JSON integrity (basic check)
    if ! grep -q '"vulnerabilities"' "$cache_file" 2>/dev/null && \
       ! grep -q '"totalResults"' "$cache_file" 2>/dev/null; then
        return 1  # Cache corrupted
    fi

    return 0  # Cache valid
}

# Store CVE query result in cache
# Args: $1=cache_key, $2=json_data
# Returns: 0 on success, 1 on failure
store_cache() {
    local cache_key="$1"
    local json_data="$2"

    if [ -z "$cache_key" ] || [ -z "$json_data" ]; then
        return 1
    fi

    # Initialize cache if needed
    init_cache || return 1

    local cache_file="$CACHE_DIR/$cache_key"

    # Add cache metadata
    local cache_entry=$(cat << EOF
{
  "cache_metadata": {
    "cached_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "ttl_hours": ${CACHE_TTL_HOURS},
    "cache_key": "${cache_key}"
  },
  "nvd_data": ${json_data}
}
EOF
)

    # Write to cache file
    echo "$cache_entry" > "$cache_file" 2>/dev/null || {
        echo "[ERROR] Failed to write cache file: $cache_file" >&2
        return 1
    }

    return 0
}

# Retrieve cached CVE data
# Args: $1=cache_key
# Returns: Cached JSON data (NVD response portion only, without cache metadata)
get_cache() {
    local cache_key="$1"

    if [ -z "$cache_key" ]; then
        return 1
    fi

    local cache_file="$CACHE_DIR/$cache_key"

    if [ ! -f "$cache_file" ]; then
        return 1  # Cache miss
    fi

    # Extract NVD data portion (skip cache metadata wrapper)
    # This uses sed to extract the nvd_data field
    sed -n '/"nvd_data":/,$ p' "$cache_file" | \
        sed '1s/.*"nvd_data": //' | \
        sed '$ s/}$//' || cat "$cache_file"

    return 0
}

# Clean old cache entries
# Args: $1=max_age_days (default: 30)
# Returns: Number of files deleted
prune_cache() {
    local max_age_days="${1:-30}"

    if [ ! -d "$CACHE_DIR" ]; then
        return 0
    fi

    # Find and delete old files
    local deleted_count=$(find "$CACHE_DIR" -name "*.json" -type f -mtime +$max_age_days -delete -print 2>/dev/null | wc -l)

    # Check size limits and prune oldest if exceeded
    local cache_size_mb=$(du -sm "$CACHE_DIR" 2>/dev/null | cut -f1)
    if [ -n "$cache_size_mb" ] && [ "$cache_size_mb" -gt "$CACHE_MAX_SIZE_MB" ]; then
        # Delete oldest 50 files to bring size down
        local additional_deleted=$(find "$CACHE_DIR" -name "*.json" -type f -printf '%T@ %p\n' 2>/dev/null | \
            sort -n | head -n 50 | cut -d' ' -f2- | xargs rm -f 2>/dev/null | wc -l)
        deleted_count=$((deleted_count + additional_deleted))
    fi

    echo "$deleted_count"
    return 0
}

# Get cache statistics
# Returns: Human-readable cache stats
cache_stats() {
    init_cache 2>/dev/null

    local file_count=$(find "$CACHE_DIR" -name "*.json" -type f 2>/dev/null | wc -l)
    local cache_size=$(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1)
    local oldest_file=$(find "$CACHE_DIR" -name "*.json" -type f -printf '%T@ %p\n' 2>/dev/null | \
                        sort -n | head -n1 | cut -d' ' -f2- | xargs basename 2>/dev/null)

    cat << EOF
Cache Statistics:
  Location: $CACHE_DIR
  Files: $file_count
  Size: $cache_size
  TTL: ${CACHE_TTL_HOURS} hours
  Oldest: ${oldest_file:-none}
EOF
}

# Clear entire cache
# Returns: 0 on success
clear_cache() {
    if [ -d "$CACHE_DIR" ]; then
        rm -f "$CACHE_DIR"/*.json 2>/dev/null
        echo "[INFO] Cache cleared"
        return 0
    fi
    return 1
}
