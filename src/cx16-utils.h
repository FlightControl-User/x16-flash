/**
 * @file cx16-utils.h
 * @author your name (you@domain.com)
 * @brief 
 * @version 0.1
 * @date 2023-10-05
 * 
 * @copyright Copyright (c) 2023
 * 
 */

#include "cx16-defines.h"
#include "cx16-globals.h"

void system_reset();
unsigned char util_wait_key(unsigned char* info_text, unsigned char* filter);
void util_wait_space();
void wait_moment(unsigned char w);
