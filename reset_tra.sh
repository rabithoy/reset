#!/bin/bash

LOG_FILE="multi_reset_xenke_fixed.log"
CONF_FILE="/root/InternetIncome-main/properties.conf"
TIME_CYCLE=21600   # 6 tiếng vòng 1
RETRY=2             # số lần retry nếu run fail

timestamp() { date +"[%Y-%m-%d %H:%M:%S] (GMT+7)"; }
log() { echo "$(timestamp) $1" | tee -a "$LOG_FILE"; }

get_token() {
    local key="$1"
    grep "^$key=" "$CONF_FILE" | cut -d '=' -f2
}

restart_container() {
    local container="$1"
    local network="$2"
    local image="$3"
    local token="$4"

    # Check network tồn tại
    if ! docker inspect "$network" >/dev/null 2>&1; then
        log "⚠️ Network $network chưa tồn tại, bỏ qua container $container"
        return
    fi

    docker rm -f "$container" >/dev/null 2>&1
    sleep 3

    local attempt
    for attempt in $(seq 1 $RETRY); do
        if docker run -d \
            --name "$container" \
            --restart=always \
            --network=container:"$network" \
            --platform=linux/amd64 \
            $image \
            start accept \
            --device-name "$container" \
            --token "$token" >/dev/null 2>&1; then
            log "✅ Restarted $container ($image) on attempt $attempt"
            break
        else
            log "⚠️ Failed to start $container ($image), attempt $attempt/$RETRY"
            sleep 5
        fi
    done
}

# ==========================
# Lấy danh sách tất cả container
# ==========================
containers_all=()

# TraffMon
TRAFFMON_TOKEN=$(get_token "TRAFFMONETIZER_TOKEN")
if [[ -n "$TRAFFMON_TOKEN" ]]; then
    docker pull traffmonetizer/cli_v2 >/dev/null 2>&1
    mapfile -t traff_containers < <(docker ps -a --filter "name=traffmon" --format "{{.Names}}")
    for c in "${traff_containers[@]}"; do
        containers_all+=("traffmon|$c|traffmonetizer/cli_v2|$TRAFFMON_TOKEN|tun${c#traffmon}")
    done
fi

# CastarSDK
CASTAR_TOKEN=$(get_token "CASTAR_SDK_KEY")
if [[ -n "$CASTAR_TOKEN" ]]; then
    CASTAR_IMAGE="ghcr.io/adfly8470/castarsdk/castarsdk@sha256:fc07c70982ae1869181acd81f0b7314b03e0601794d4e7532b7f8435e971eaa8"
    docker pull "$CASTAR_IMAGE" >/dev/null 2>&1
    mapfile -t castar_containers < <(docker ps -a --filter "name=castarsdk" --format "{{.Names}}")
    for c in "${castar_containers[@]}"; do
        containers_all+=("castarsdk|$c|$CASTAR_IMAGE|$CASTAR_TOKEN|tun${c#castarsdk}")
    done
fi

TOTAL=${#containers_all[@]}
if [[ $TOTAL -eq 0 ]]; then
    log "❌ Không tìm thấy container TraffMon hoặc CastarSDK"
    exit 1
fi

INTERVAL=$(( TIME_CYCLE / TOTAL ))
log "🔑 TOTAL containers=$TOTAL, INTERVAL between resets=$INTERVAL s"

# ==========================
# Reset từng container xen kẽ
# ==========================
for entry in "${containers_all[@]}"; do
    IFS='|' read -r prefix name image token network <<< "$entry"
    restart_container "$name" "$network" "$image" "$token"
    log "⏳ Sleeping $INTERVAL s trước container tiếp theo"
    sleep $INTERVAL
done

log "🎉 DONE! All containers processed."
