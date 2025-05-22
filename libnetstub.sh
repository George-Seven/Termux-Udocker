#!/bin/sh

# Refer to https://github.com/George-Seven/Termux-Proot-Utils

load_libnetstub(){

mkdir -p /.libnetstub

cd /.libnetstub

# Check dependencies
for cmd in gcc; do
    if ! command -v $cmd &>/dev/null; then
        # echo "$cmd not found (required)" >&2
        return 1
    fi
done

# Create libnetstub.so
if [ ! -f libnetstub.so ]; then
echo '
#define _GNU_SOURCE
#include <dlfcn.h>
#include <ifaddrs.h>
#include <net/if.h>
#include <netinet/in.h>
#include <linux/if_packet.h>
#include <linux/netlink.h>
#include <linux/rtnetlink.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <stdbool.h>

// Original function pointers
static int (*original_getifaddrs)(struct ifaddrs **) = NULL;
static void (*original_freeifaddrs)(struct ifaddrs *) = NULL;
static char* (*original_if_indextoname)(unsigned int, char*) = NULL;
static unsigned int (*original_if_nametoindex)(const char*) = NULL;
static struct if_nameindex* (*original_if_nameindex)(void) = NULL;
static void (*original_if_freenameindex)(struct if_nameindex*) = NULL;

// Android-compatible implementation

typedef struct {
    int fd;
    char* data;
    size_t size;
} NetlinkConnection;

static NetlinkConnection netlink_connect() {
    NetlinkConnection nc = { .fd = -1, .data = NULL, .size = 8192 };
    nc.data = malloc(nc.size);
    if (nc.data) {
        nc.fd = socket(PF_NETLINK, SOCK_RAW | SOCK_CLOEXEC, NETLINK_ROUTE);
    }
    return nc;
}

static void netlink_disconnect(NetlinkConnection* nc) {
    if (nc->fd != -1) close(nc->fd);
    free(nc->data);
    nc->fd = -1;
    nc->data = NULL;
}

static bool netlink_send_request(NetlinkConnection* nc, int type) {
    if (!nc->data || nc->fd == -1) return false;
    
    struct {
        struct nlmsghdr hdr;
        struct rtgenmsg msg;
    } request;
    
    memset(&request, 0, sizeof(request));
    request.hdr.nlmsg_flags = NLM_F_DUMP | NLM_F_REQUEST;
    request.hdr.nlmsg_type = type;
    request.hdr.nlmsg_len = sizeof(request);
    request.msg.rtgen_family = AF_UNSPEC;
    
    return send(nc->fd, &request, sizeof(request), 0) == sizeof(request);
}

struct ifaddrs_storage {
    struct ifaddrs ifa;
    int interface_index;
    struct sockaddr_storage addr;
    struct sockaddr_storage netmask;
    struct sockaddr_storage ifa_ifu;
    char name[IFNAMSIZ + 1];
};

static uint8_t* sockaddr_bytes(int family, struct sockaddr_storage* ss) {
    if (family == AF_INET) {
        struct sockaddr_in* ss4 = (struct sockaddr_in*)ss;
        return (uint8_t*)&ss4->sin_addr;
    } else if (family == AF_INET6) {
        struct sockaddr_in6* ss6 = (struct sockaddr_in6*)ss;
        return (uint8_t*)&ss6->sin6_addr;
    } else if (family == AF_PACKET) {
        struct sockaddr_ll* sll = (struct sockaddr_ll*)ss;
        return (uint8_t*)&sll->sll_addr;
    }
    return NULL;
}

static struct sockaddr* copy_address(int family, const void* data, size_t byteCount, 
                                   struct sockaddr_storage* ss, int interface_index) {
    ss->ss_family = family;
    uint8_t* dst = sockaddr_bytes(family, ss);
    if (dst) {
        memcpy(dst, data, byteCount);
    }
    
    if (family == AF_INET6 && 
        (IN6_IS_ADDR_LINKLOCAL(data) || IN6_IS_ADDR_MC_LINKLOCAL(data))) {
        ((struct sockaddr_in6*)ss)->sin6_scope_id = interface_index;
    }
    
    return (struct sockaddr*)ss;
}

static void __getifaddrs_callback(void* context, struct nlmsghdr* hdr) {
    struct ifaddrs** out = (struct ifaddrs**)context;
    
    if (hdr->nlmsg_type == RTM_NEWLINK) {
        struct ifinfomsg* ifi = (struct ifinfomsg*)NLMSG_DATA(hdr);
        struct ifaddrs_storage* new_addr = malloc(sizeof(struct ifaddrs_storage));
        if (!new_addr) return;
        
        memset(new_addr, 0, sizeof(*new_addr));
        new_addr->ifa.ifa_next = *out;
        *out = (struct ifaddrs*)new_addr;
        
        new_addr->interface_index = ifi->ifi_index;
        new_addr->ifa.ifa_flags = ifi->ifi_flags;
        
        struct rtattr* rta = IFLA_RTA(ifi);
        size_t rta_len = IFLA_PAYLOAD(hdr);
        
        while (RTA_OK(rta, rta_len)) {
            if (rta->rta_type == IFLA_ADDRESS) {
                if (RTA_PAYLOAD(rta) <= sizeof(new_addr->addr)) {
                    new_addr->ifa.ifa_addr = copy_address(AF_PACKET, RTA_DATA(rta), 
                                                         RTA_PAYLOAD(rta), 
                                                         &new_addr->addr,
                                                         new_addr->interface_index);
                    
                    struct sockaddr_ll* sll = (struct sockaddr_ll*)&new_addr->addr;
                    sll->sll_ifindex = ifi->ifi_index;
                    sll->sll_hatype = ifi->ifi_type;
                    sll->sll_halen = RTA_PAYLOAD(rta);
                }
            } else if (rta->rta_type == IFLA_BROADCAST) {
                if (RTA_PAYLOAD(rta) <= sizeof(new_addr->ifa_ifu)) {
                    new_addr->ifa.ifa_broadaddr = copy_address(AF_PACKET, RTA_DATA(rta), 
                                                             RTA_PAYLOAD(rta), 
                                                             &new_addr->ifa_ifu,
                                                             new_addr->interface_index);
                    
                    struct sockaddr_ll* sll = (struct sockaddr_ll*)&new_addr->ifa_ifu;
                    sll->sll_ifindex = ifi->ifi_index;
                    sll->sll_hatype = ifi->ifi_type;
                    sll->sll_halen = RTA_PAYLOAD(rta);
                }
            } else if (rta->rta_type == IFLA_IFNAME) {
                if (RTA_PAYLOAD(rta) < sizeof(new_addr->name)) {
                    strncpy(new_addr->name, RTA_DATA(rta), RTA_PAYLOAD(rta));
                    new_addr->name[RTA_PAYLOAD(rta)] = '\''\0'\'';
                    new_addr->ifa.ifa_name = new_addr->name;
                }
            }
            rta = RTA_NEXT(rta, rta_len);
        }
    } else if (hdr->nlmsg_type == RTM_NEWADDR) {
        struct ifaddrmsg* msg = (struct ifaddrmsg*)NLMSG_DATA(hdr);
        struct ifaddrs_storage* known_addr = (struct ifaddrs_storage*)*out;
        
        while (known_addr && known_addr->interface_index != (int)msg->ifa_index) {
            known_addr = (struct ifaddrs_storage*)known_addr->ifa.ifa_next;
        }
        
        struct ifaddrs_storage* new_addr = malloc(sizeof(struct ifaddrs_storage));
        if (!new_addr) return;
        
        memset(new_addr, 0, sizeof(*new_addr));
        new_addr->ifa.ifa_next = *out;
        *out = (struct ifaddrs*)new_addr;
        
        new_addr->interface_index = (int)msg->ifa_index;
        
        if (known_addr) {
            strncpy(new_addr->name, known_addr->name, IFNAMSIZ);
            new_addr->ifa.ifa_name = new_addr->name;
            new_addr->ifa.ifa_flags = known_addr->ifa.ifa_flags;
        }
        
        struct rtattr* rta = IFA_RTA(msg);
        size_t rta_len = IFA_PAYLOAD(hdr);
        
        while (RTA_OK(rta, rta_len)) {
            if (rta->rta_type == IFA_ADDRESS) {
                if (msg->ifa_family == AF_INET || msg->ifa_family == AF_INET6) {
                    new_addr->ifa.ifa_addr = copy_address(msg->ifa_family, RTA_DATA(rta),
                                                        RTA_PAYLOAD(rta),
                                                        &new_addr->addr,
                                                        new_addr->interface_index);
                    
                    // Set netmask
                    new_addr->netmask.ss_family = msg->ifa_family;
                    uint8_t* dst = sockaddr_bytes(msg->ifa_family, &new_addr->netmask);
                    if (dst) {
                        size_t prefix_length = msg->ifa_prefixlen;
                        memset(dst, 0xff, prefix_length / 8);
                        if ((prefix_length % 8) != 0) {
                            dst[prefix_length/8] = (0xff << (8 - (prefix_length % 8)));
                        }
                        new_addr->ifa.ifa_netmask = (struct sockaddr*)&new_addr->netmask;
                    }
                }
            } else if (rta->rta_type == IFA_BROADCAST) {
                if (msg->ifa_family == AF_INET) {
                    new_addr->ifa.ifa_broadaddr = copy_address(msg->ifa_family, RTA_DATA(rta),
                                                              RTA_PAYLOAD(rta),
                                                              &new_addr->ifa_ifu,
                                                              new_addr->interface_index);
                    if (!known_addr) {
                        new_addr->ifa.ifa_flags |= IFF_BROADCAST;
                    }
                }
            } else if (rta->rta_type == IFA_LOCAL) {
                if (msg->ifa_family == AF_INET || msg->ifa_family == AF_INET6) {
                    if (new_addr->ifa.ifa_addr) {
                        memcpy(&new_addr->ifa_ifu, &new_addr->addr, sizeof(new_addr->addr));
                        new_addr->ifa.ifa_dstaddr = (struct sockaddr*)&new_addr->ifa_ifu;
                    }
                    new_addr->ifa.ifa_addr = copy_address(msg->ifa_family, RTA_DATA(rta),
                                                        RTA_PAYLOAD(rta),
                                                        &new_addr->addr,
                                                        new_addr->interface_index);
                }
            } else if (rta->rta_type == IFA_LABEL) {
                if (RTA_PAYLOAD(rta) < sizeof(new_addr->name)) {
                    strncpy(new_addr->name, RTA_DATA(rta), RTA_PAYLOAD(rta));
                    new_addr->name[RTA_PAYLOAD(rta)] = '\''\0'\'';
                    new_addr->ifa.ifa_name = new_addr->name;
                }
            }
            rta = RTA_NEXT(rta, rta_len);
        }
    }
}

static bool netlink_read_responses(NetlinkConnection* nc, 
                                  void (*callback)(void*, struct nlmsghdr*), 
                                  void* context) {
    ssize_t bytes_read;
    while ((bytes_read = recv(nc->fd, nc->data, nc->size, 0)) > 0) {
        struct nlmsghdr* hdr = (struct nlmsghdr*)nc->data;
        
        for (; NLMSG_OK(hdr, (size_t)bytes_read); hdr = NLMSG_NEXT(hdr, bytes_read)) {
            if (hdr->nlmsg_type == NLMSG_DONE) return true;
            if (hdr->nlmsg_type == NLMSG_ERROR) {
                struct nlmsgerr* err = (struct nlmsgerr*)NLMSG_DATA(hdr);
                errno = (hdr->nlmsg_len >= NLMSG_LENGTH(sizeof(struct nlmsgerr))) ? 
                    -err->error : EIO;
                return false;
            }
            callback(context, hdr);
        }
    }
    return false;
}

static void resolve_or_remove_nameless_interfaces(struct ifaddrs** list) {
    struct ifaddrs_storage* addr = (struct ifaddrs_storage*)*list;
    struct ifaddrs_storage* prev_addr = NULL;
    
    while (addr) {
        struct ifaddrs* next_addr = addr->ifa.ifa_next;
        
        if (strlen(addr->name) == 0) {
            if (if_indextoname(addr->interface_index, addr->name)) {
                addr->ifa.ifa_name = addr->name;
            }
        }
        
        if (strlen(addr->name) == 0) {
            if (prev_addr == NULL) {
                *list = next_addr;
            } else {
                prev_addr->ifa.ifa_next = next_addr;
            }
            free(addr);
        } else {
            prev_addr = addr;
        }
        
        addr = (struct ifaddrs_storage*)next_addr;
    }
}

static void get_interface_flags_via_ioctl(struct ifaddrs** list) {
    int s = socket(AF_INET, SOCK_DGRAM | SOCK_CLOEXEC, 0);
    if (s == -1) return;
    
    for (struct ifaddrs_storage* addr = (struct ifaddrs_storage*)*list; addr; 
         addr = (struct ifaddrs_storage*)addr->ifa.ifa_next) {
        struct ifreq ifr = {};
        strncpy(ifr.ifr_name, addr->ifa.ifa_name, sizeof(ifr.ifr_name));
        if (ioctl(s, SIOCGIFFLAGS, &ifr) != -1) {
            addr->ifa.ifa_flags = ifr.ifr_flags;
        }
    }
    
    close(s);
}

// Overridden functions

int getifaddrs(struct ifaddrs** out) {
    if (!original_getifaddrs) {
        original_getifaddrs = dlsym(RTLD_NEXT, "getifaddrs");
    }
    
    *out = NULL;
    NetlinkConnection nc = netlink_connect();
    if (nc.fd == -1 || !nc.data) {
        netlink_disconnect(&nc);
        return original_getifaddrs ? original_getifaddrs(out) : -1;
    }
    
    bool getlink_success = false;
    if (getuid() < 10000) { // First application UID approximation
        getlink_success = netlink_send_request(&nc, RTM_GETLINK) && 
                          netlink_read_responses(&nc, __getifaddrs_callback, out);
    }
    
    bool getaddr_success = netlink_send_request(&nc, RTM_GETADDR) && 
                          netlink_read_responses(&nc, __getifaddrs_callback, out);
    
    netlink_disconnect(&nc);
    
    if (!getaddr_success) {
        freeifaddrs(*out);
        *out = NULL;
        return -1;
    }
    
    if (!getlink_success) {
        resolve_or_remove_nameless_interfaces(out);
        get_interface_flags_via_ioctl(out);
    }
    
    return 0;
}

void freeifaddrs(struct ifaddrs* list) {
    if (!original_freeifaddrs) {
        original_freeifaddrs = dlsym(RTLD_NEXT, "freeifaddrs");
    }
    
    while (list) {
        struct ifaddrs* current = list;
        list = list->ifa_next;
        free(current);
    }
}

char* if_indextoname(unsigned int ifindex, char* ifname) {
    if (!original_if_indextoname) {
        original_if_indextoname = dlsym(RTLD_NEXT, "if_indextoname");
    }
    
    int s = socket(AF_INET, SOCK_DGRAM | SOCK_CLOEXEC, 0);
    if (s == -1) return NULL;
    
    struct ifreq ifr = { .ifr_ifindex = (int)ifindex };
    if (ioctl(s, SIOCGIFNAME, &ifr) == -1) {
        close(s);
        return NULL;
    }
    
    close(s);
    strncpy(ifname, ifr.ifr_name, IFNAMSIZ);
    ifname[IFNAMSIZ - 1] = '\''\0'\'';
    return ifname;
}

unsigned int if_nametoindex(const char* ifname) {
    if (!original_if_nametoindex) {
        original_if_nametoindex = dlsym(RTLD_NEXT, "if_nametoindex");
    }
    
    int s = socket(AF_INET, SOCK_DGRAM | SOCK_CLOEXEC, 0);
    if (s == -1) return 0;
    
    struct ifreq ifr = {};
    strncpy(ifr.ifr_name, ifname, sizeof(ifr.ifr_name));
    ifr.ifr_name[IFNAMSIZ - 1] = '\''\0'\'';
    
    if (ioctl(s, SIOCGIFINDEX, &ifr) == -1) {
        close(s);
        return 0;
    }
    
    close(s);
    return ifr.ifr_ifindex;
}

struct if_list {
    struct if_list* next;
    struct if_nameindex data;
};

static void __if_nameindex_callback(void* context, struct nlmsghdr* hdr) {
    struct if_list** list = (struct if_list**)context;
    
    if (hdr->nlmsg_type == RTM_NEWLINK) {
        struct ifinfomsg* ifi = (struct ifinfomsg*)NLMSG_DATA(hdr);
        struct if_list* new_link = malloc(sizeof(struct if_list));
        if (!new_link) return;
        
        new_link->next = *list;
        *list = new_link;
        
        new_link->data.if_index = ifi->ifi_index;
        new_link->data.if_name = NULL;
        
        struct rtattr* rta = IFLA_RTA(ifi);
        size_t rta_len = IFLA_PAYLOAD(hdr);
        
        while (RTA_OK(rta, rta_len)) {
            if (rta->rta_type == IFLA_IFNAME) {
                new_link->data.if_name = strndup((char*)RTA_DATA(rta), RTA_PAYLOAD(rta));
            }
            rta = RTA_NEXT(rta, rta_len);
        }
    }
}

struct if_nameindex* if_nameindex() {
    if (!original_if_nameindex) {
        original_if_nameindex = dlsym(RTLD_NEXT, "if_nameindex");
    }
    
    struct if_list* list = NULL;
    NetlinkConnection nc = netlink_connect();
    if (nc.fd == -1 || !nc.data) {
        netlink_disconnect(&nc);
        return original_if_nameindex ? original_if_nameindex() : NULL;
    }
    
    bool okay = netlink_send_request(&nc, RTM_GETLINK) && 
                netlink_read_responses(&nc, __if_nameindex_callback, &list);
    netlink_disconnect(&nc);
    
    if (!okay) {
        while (list) {
            struct if_list* next = list->next;
            free(list->data.if_name);
            free(list);
            list = next;
        }
        return NULL;
    }
    
    size_t count = 0;
    for (struct if_list* it = list; it; it = it->next) {
        count++;
    }
    
    struct if_nameindex* result = malloc((count + 1) * sizeof(struct if_nameindex));
    if (!result) {
        while (list) {
            struct if_list* next = list->next;
            free(list->data.if_name);
            free(list);
            list = next;
        }
        return NULL;
    }
    
    struct if_nameindex* out = result;
    for (struct if_list* it = list; it; it = it->next) {
        out->if_index = it->data.if_index;
        out->if_name = it->data.if_name;
        out++;
    }
    
    out->if_index = 0;
    out->if_name = NULL;
    
    while (list) {
        struct if_list* next = list->next;
        free(list);
        list = next;
    }
    
    return result;
}

void if_freenameindex(struct if_nameindex* array) {
    if (!original_if_freenameindex) {
        original_if_freenameindex = dlsym(RTLD_NEXT, "if_freenameindex");
    }
    
    if (!array) return;
    
    struct if_nameindex* ptr = array;
    while (ptr->if_index != 0 || ptr->if_name != NULL) {
        free(ptr->if_name);
        ptr++;
    }
    
    free(array);
}

// Library constructor
__attribute__((constructor)) static void init() {
    original_getifaddrs = dlsym(RTLD_NEXT, "getifaddrs");
    original_freeifaddrs = dlsym(RTLD_NEXT, "freeifaddrs");
    original_if_indextoname = dlsym(RTLD_NEXT, "if_indextoname");
    original_if_nametoindex = dlsym(RTLD_NEXT, "if_nametoindex");
    original_if_nameindex = dlsym(RTLD_NEXT, "if_nameindex");
    original_if_freenameindex = dlsym(RTLD_NEXT, "if_freenameindex");
}
' | gcc -x c -s -fPIC -shared -o libnetstub.so - >/dev/null || return 1
fi

# Patch python ctypes. Since python3, the LD_PRELOAD for stub functions does not work directly with it
# Refer to https://stackoverflow.com/q/76521902
for cmd in patch python3; do
    if ! command -v $cmd &>/dev/null; then
        # echo "$cmd not found (optional)" >&2
        return 0
    fi
done

echo '
@@ -339,6 +339,9 @@
             return result
 
         def find_library(name):
+            if (name == "c" or name == "libc.so.6") and os.path.exists("PLACEHOLDER"):
+                return "PLACEHOLDER"
+
             # See issue #9998
             return _findSoname_ldconfig(name) or \
                    _get_soname(_findLib_gcc(name)) or _get_soname(_findLib_ld(name))
' | sed "s|PLACEHOLDER|$(pwd)/libnetstub.so|g" | patch -f -p0 --no-backup-if-mismatch -r /dev/null "$(dirname "$(python3 -c "import ctypes; print(ctypes.__file__)")")/util.py" &>/dev/null || true

# Alpine specific fixes
echo '
@@ -288,6 +288,8 @@
                 name = '\''c'\''
             elif name in ['\''libm.so'\'', '\''libcrypt.so'\'', '\''libpthread.so'\'']:
                 name = '\''libc.so'\''
+            if (name == "c" or name == "libc.so") and os.path.exists("PLACEHOLDER"):
+                return "PLACEHOLDER"
             # search in standard locations (musl order)
             paths = ['\''/lib'\'', '\''/usr/local/lib'\'', '\''/usr/lib'\'']
             if '\''LD_LIBRARY_PATH'\'' in os.environ:
' | sed "s|PLACEHOLDER|$(pwd)/libnetstub.so|g" | patch -s -f -p0 --no-backup-if-mismatch -r /dev/null "$(dirname "$(python3 -c "import ctypes; print(ctypes.__file__)")")/util.py" &>/dev/null || true

}

$(load_libnetstub)

if [ -f /.libnetstub/libnetstub.so ]; then
    export LD_PRELOAD="/.libnetstub/libnetstub.so"
fi

unset load_libnetstub
