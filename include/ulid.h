#ifndef ULID_H
#define ULID_H
#include <stdint.h>

typedef struct {
    uint32_t timestamp_high;
    uint16_t timestamp_low;
    uint16_t random_high;
    uint32_t random_mid;
    uint32_t random_low;
} ULID;

ULID ULID_create();
void ULID_str(ULID const* ulid, char* buf, uint64_t len);
int ULID_parse(ULID* ulid, char const* str, uint64_t len);

#endif
