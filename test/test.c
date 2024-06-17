#include "ulid.h"
#include <stdio.h>
#include <string.h>

void print_ulid(ULID const* ulid) {
    printf("	timestamp_high = 0x%x\n", ulid->timestamp_high);
    printf("	timestamp_low = 0x%x\n", ulid->timestamp_low);
    printf("	random_high = 0x%x\n", ulid->random_high);
    printf("	random_mid = 0x%x\n", ulid->random_mid);
    printf("	random_low = 0x%x\n", ulid->random_low);
}

void create_ulid() {
    ULID ulid = ULID_create();
    char buf[27];
    memset(buf, 0, 27);
    ULID_str(&ulid, buf, 26);
    printf("ULID generated:\n");
    print_ulid(&ulid);
    printf("	%s\n", buf);
}

int parse_ulid() {
    ULID ulid;

    int ret = ULID_parse(&ulid, "F0YYKH0J10YXE0BYD4VMT2911D", 26);
    if (ret) {
        return ret;
    }

    char buf[27];
    memset(buf, 0, 27);
    ULID_str(&ulid, buf, 26);
    printf("ULID parsed:\n");
    print_ulid(&ulid);
    printf("	%s\n", buf);

    return 0;
}

int main(void) {
    create_ulid();

    int ret = parse_ulid();
    if (ret) {
        return ret;
    }

    return 0;
}
