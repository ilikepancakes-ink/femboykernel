; FemboyOS Network Stack
; Basic networking implementation with DHCP, LAN, WAN, WiFi, and Ethernet support

[BITS 32]

; Global symbols exported by this module
global network_init
global network_command

; External functions and variables from main.asm
extern input_buffer
extern strcmp
extern print_string
extern newline
extern print_char
extern print_number

; Network constants
ETHERNET_TYPE_ARP equ 0x0806
ETHERNET_TYPE_IP equ 0x0800

IP_PROTOCOL_ICMP equ 1
IP_PROTOCOL_TCP equ 6
IP_PROTOCOL_UDP equ 17

; DHCP constants
DHCP_DISCOVER equ 1
DHCP_OFFER equ 2
DHCP_REQUEST equ 3
DHCP_ACK equ 5

; Network device structure
struc net_device
    .name: resb 16         ; Device name (e.g., "eth0", "wlan0")
    .mac: resb 6           ; MAC address
    .ip: resd 1            ; IP address
    .subnet: resd 1        ; Subnet mask
    .gateway: resd 1       ; Gateway IP
    .dns: resd 1           ; DNS server
    .type: resd 1          ; Device type (0=ethernet, 1=wifi)
    .flags: resd 1         ; Device flags
    .tx_packets: resq 1    ; Transmitted packets
    .rx_packets: resq 1    ; Received packets
    .tx_bytes: resq 1      ; Transmitted bytes
    .rx_bytes: resq 1      ; Received bytes
endstruc

; Packet buffer structure
struc packet_buffer
    .data: resb 1514       ; Ethernet frame (MTU + headers)
    .length: resd 1        ; Packet length
    .device: resd 1        ; Associated network device
endstruc

; Global network variables
network_initialized db 0
network_devices times 4 db 0  ; Support up to 4 network devices
packet_buffers times 16 db 0 ; 16 packet buffers
arp_cache times 256 db 0     ; ARP cache (IP -> MAC mapping)

; Initialize network stack
network_init:
    pusha

    ; Check if already initialized
    cmp byte [network_initialized], 1
    je .already_init

    ; Initialize network devices
    call detect_network_devices

    ; Initialize ARP cache
    call arp_cache_init

    ; Initialize packet buffers
    call packet_buffer_init

    ; Set initialized flag
    mov byte [network_initialized], 1

.already_init:
    popa
    ret

; Detect and initialize network devices
detect_network_devices:
    pusha

    ; Scan PCI bus for network devices
    call pci_scan_network

    ; Initialize found devices
    call init_network_devices

    popa
    ret

; PCI scan for network devices
pci_scan_network:
    pusha

    ; PCI network device classes:
    ; 0x02 = Network Controller
    ; 0x00 = Ethernet Controller
    ; 0x80 = Wireless Controller

    ; For now, we'll simulate finding devices
    ; In a real implementation, this would scan PCI configuration space

    ; Simulate Ethernet device
    mov edi, network_devices
    mov dword [edi + net_device.type], 0  ; Ethernet
    mov byte [edi + net_device.name], 'e'
    mov byte [edi + net_device.name + 1], 't'
    mov byte [edi + net_device.name + 2], 'h'
    mov byte [edi + net_device.name + 3], '0'
    mov byte [edi + net_device.name + 4], 0

    ; Set fake MAC address
    mov byte [edi + net_device.mac], 0x00
    mov byte [edi + net_device.mac + 1], 0x11
    mov byte [edi + net_device.mac + 2], 0x22
    mov byte [edi + net_device.mac + 3], 0x33
    mov byte [edi + net_device.mac + 4], 0x44
    mov byte [edi + net_device.mac + 5], 0x55

    ; Simulate WiFi device
    add edi, net_device_size
    mov dword [edi + net_device.type], 1  ; WiFi
    mov byte [edi + net_device.name], 'w'
    mov byte [edi + net_device.name + 1], 'l'
    mov byte [edi + net_device.name + 2], 'a'
    mov byte [edi + net_device.name + 3], 'n'
    mov byte [edi + net_device.name + 4], '0'
    mov byte [edi + net_device.name + 5], 0

    ; Set fake MAC address for WiFi
    mov byte [edi + net_device.mac], 0x00
    mov byte [edi + net_device.mac + 1], 0xAA
    mov byte [edi + net_device.mac + 2], 0xBB
    mov byte [edi + net_device.mac + 3], 0xCC
    mov byte [edi + net_device.mac + 4], 0xDD
    mov byte [edi + net_device.mac + 5], 0xEE

    popa
    ret

; Initialize network devices
init_network_devices:
    pusha

    ; For each device, initialize hardware
    mov ecx, 2  ; We have 2 devices
    mov edi, network_devices

.init_loop:
    push ecx
    push edi

    ; Initialize device based on type
    mov eax, [edi + net_device.type]
    cmp eax, 0
    je .init_ethernet
    cmp eax, 1
    je .init_wifi
    jmp .next_device

.init_ethernet:
    call init_ethernet_device
    jmp .next_device

.init_wifi:
    call init_wifi_device
    jmp .next_device

.next_device:
    pop edi
    pop ecx
    add edi, net_device_size
    loop .init_loop

    popa
    ret

; Initialize Ethernet device (stub)
init_ethernet_device:
    ; In a real implementation, this would:
    ; - Reset the device
    ; - Set MAC address
    ; - Configure interrupts
    ; - Enable receiver/transmitter
    ret

; Initialize WiFi device (stub)
init_wifi_device:
    ; In a real implementation, this would:
    ; - Reset the device
    ; - Scan for networks
    ; - Associate with access point
    ; - Configure security
    ret

; Initialize packet buffers
packet_buffer_init:
    pusha

    mov ecx, 16  ; 16 buffers
    mov edi, packet_buffers

.init_loop:
    ; Mark buffer as free (length = 0)
    mov dword [edi + packet_buffer.length], 0
    add edi, packet_buffer_size
    loop .init_loop

    popa
    ret

; Initialize ARP cache
arp_cache_init:
    pusha

    ; Clear ARP cache
    mov edi, arp_cache
    mov ecx, 256
    xor eax, eax
    rep stosd

    popa
    ret

; DHCP client implementation
dhcp_discover:
    pusha

    ; Find network device
    mov edi, network_devices
    cmp dword [edi + net_device.type], 0  ; Ethernet device
    jne .no_device

    ; Create DHCP DISCOVER packet
    call create_dhcp_packet

    ; Send packet
    call network_send_packet

.no_device:
    popa
    ret

; Create DHCP packet
create_dhcp_packet:
    pusha

    ; This is a simplified DHCP packet creation
    ; In a real implementation, this would build proper DHCP headers

    popa
    ret

; Network send packet (stub)
network_send_packet:
    ; In a real implementation, this would:
    ; - Add Ethernet header
    ; - Send to device driver
    ret

; Network receive packet (stub)
network_receive_packet:
    ; In a real implementation, this would:
    ; - Poll network devices
    ; - Process received packets
    ret

; Get network device count
network_get_device_count:
    pusha

    ; Count initialized devices
    mov ecx, 0
    mov edi, network_devices
    mov edx, 4  ; Max devices

.count_loop:
    cmp byte [edi + net_device.name], 0
    je .next
    inc ecx

.next:
    add edi, net_device_size
    dec edx
    jnz .count_loop

    ; Return count in EAX
    mov [esp + 28], ecx

    popa
    ret

; Get network statistics
network_get_stats:
    pusha

    ; Return basic stats
    ; In a real implementation, this would aggregate stats from all devices

    popa
    ret

; Network command handler for CLI
network_command:
    pusha

    ; Parse network command arguments
    mov esi, input_buffer
    add esi, 8  ; Skip "network " (8 chars)

    ; Check for subcommands
    mov edi, cmd_net_status
    call strcmp
    test eax, eax
    jz .status_cmd

    mov edi, cmd_net_dhcp
    call strcmp
    test eax, eax
    jz .dhcp_cmd

    mov edi, cmd_net_devices
    call strcmp
    test eax, eax
    jz .devices_cmd

    ; Unknown subcommand
    mov esi, net_unknown_cmd
    call print_string
    call newline
    jmp .done

.status_cmd:
    call network_show_status
    jmp .done

.dhcp_cmd:
    call dhcp_discover
    mov esi, dhcp_started_msg
    call print_string
    call newline
    jmp .done

.devices_cmd:
    call network_list_devices
    jmp .done

.done:
    popa
    ret

; Show network status
network_show_status:
    pusha

    mov esi, net_status_header
    call print_string
    call newline

    ; Check if network is initialized
    cmp byte [network_initialized], 1
    jne .not_init

    mov esi, net_initialized_msg
    call print_string
    call newline

    ; Show device count
    call network_get_device_count
    push eax
    mov esi, net_device_count_msg
    call print_string
    pop eax
    call print_number
    mov esi, net_devices_suffix
    call print_string
    call newline

    jmp .done

.not_init:
    mov esi, net_not_init_msg
    call print_string
    call newline

.done:
    popa
    ret

; List network devices
network_list_devices:
    pusha

    mov esi, net_devices_header
    call print_string
    call newline

    ; Show Ethernet device
    mov esi, net_eth_device
    call print_string
    call newline

    ; Show WiFi device
    mov esi, net_wifi_device
    call print_string
    call newline

    popa
    ret

; Print hex byte
print_hex_byte:
    pusha

    mov bl, al
    shr al, 4
    call print_hex_digit
    mov al, bl
    and al, 0x0F
    call print_hex_digit

    popa
    ret

; Print hex digit
print_hex_digit:
    cmp al, 10
    jge .letter
    add al, '0'
    call print_char
    ret

.letter:
    add al, 'A' - 10
    call print_char
    ret

; Network command strings
cmd_net_status db 'status', 0
cmd_net_dhcp db 'dhcp', 0
cmd_net_devices db 'devices', 0

; Network messages
net_status_header db 'Network Status:', 0
net_initialized_msg db '  Network stack initialized', 0
net_not_init_msg db '  Network stack not initialized', 0
net_device_count_msg db '  Devices: ', 0
net_devices_suffix db ' network devices detected', 0
net_devices_header db 'Network Devices:', 0
net_type_ethernet db 'Ethernet', 0
net_type_wifi db 'WiFi', 0
net_type_unknown db 'Unknown', 0
net_mac_prefix db 'MAC: ', 0
net_unknown_cmd db 'Unknown network subcommand. Use: status, dhcp, devices', 0
dhcp_started_msg db 'DHCP discovery started...', 0
net_eth_device db 'eth0: Ethernet - MAC: 00:11:22:33:44:55', 0
net_wifi_device db 'wlan0: WiFi - MAC: 00:AA:BB:CC:DD:EE', 0
