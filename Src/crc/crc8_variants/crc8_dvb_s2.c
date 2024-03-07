/****************************************************************************
 *
 *   Copyright (c) 2023 IMProject Development Team. All rights reserved.
 *   Authors: Igor Misic <igy1000mb@gmail.com>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 * 3. Neither the name IMProject nor the names of its contributors may be
 *    used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 ****************************************************************************/

#include "crc8_dvb_s2.h"

#include "crc8_base.h"

#define INITIAL_CRC8_VALUE (0x0U)
#define FINAL_XOR_VALUE (0x0U)
#define REFLECTED_OUTPUT (false)
#define REFLECTED_INPUT (false)
#define FINAL_XOR (false)

uint8_t
Crc8_dvbS2(
    const uint8_t* crc_data_ptr,
    uint32_t crc_length,
    const uint8_t* last_crc_ptr) {

    /* Table for CRC-8 DVB S2 (Polynomial 0xD5) */
    static const uint8_t crc_table[256] = {
        0x00U, 0xD5U, 0x7FU, 0xAAU, 0xFEU, 0x2BU, 0x81U, 0x54U, 0x29U, 0xFCU, 0x56U, 0x83U, 0xD7U, 0x02U, 0xA8U, 0x7DU,
        0x52U, 0x87U, 0x2DU, 0xF8U, 0xACU, 0x79U, 0xD3U, 0x06U, 0x7BU, 0xAEU, 0x04U, 0xD1U, 0x85U, 0x50U, 0xFAU, 0x2FU,
        0xA4U, 0x71U, 0xDBU, 0x0EU, 0x5AU, 0x8FU, 0x25U, 0xF0U, 0x8DU, 0x58U, 0xF2U, 0x27U, 0x73U, 0xA6U, 0x0CU, 0xD9U,
        0xF6U, 0x23U, 0x89U, 0x5CU, 0x08U, 0xDDU, 0x77U, 0xA2U, 0xDFU, 0x0AU, 0xA0U, 0x75U, 0x21U, 0xF4U, 0x5EU, 0x8BU,
        0x9DU, 0x48U, 0xE2U, 0x37U, 0x63U, 0xB6U, 0x1CU, 0xC9U, 0xB4U, 0x61U, 0xCBU, 0x1EU, 0x4AU, 0x9FU, 0x35U, 0xE0U,
        0xCFU, 0x1AU, 0xB0U, 0x65U, 0x31U, 0xE4U, 0x4EU, 0x9BU, 0xE6U, 0x33U, 0x99U, 0x4CU, 0x18U, 0xCDU, 0x67U, 0xB2U,
        0x39U, 0xECU, 0x46U, 0x93U, 0xC7U, 0x12U, 0xB8U, 0x6DU, 0x10U, 0xC5U, 0x6FU, 0xBAU, 0xEEU, 0x3BU, 0x91U, 0x44U,
        0x6BU, 0xBEU, 0x14U, 0xC1U, 0x95U, 0x40U, 0xEAU, 0x3FU, 0x42U, 0x97U, 0x3DU, 0xE8U, 0xBCU, 0x69U, 0xC3U, 0x16U,
        0xEFU, 0x3AU, 0x90U, 0x45U, 0x11U, 0xC4U, 0x6EU, 0xBBU, 0xC6U, 0x13U, 0xB9U, 0x6CU, 0x38U, 0xEDU, 0x47U, 0x92U,
        0xBDU, 0x68U, 0xC2U, 0x17U, 0x43U, 0x96U, 0x3CU, 0xE9U, 0x94U, 0x41U, 0xEBU, 0x3EU, 0x6AU, 0xBFU, 0x15U, 0xC0U,
        0x4BU, 0x9EU, 0x34U, 0xE1U, 0xB5U, 0x60U, 0xCAU, 0x1FU, 0x62U, 0xB7U, 0x1DU, 0xC8U, 0x9CU, 0x49U, 0xE3U, 0x36U,
        0x19U, 0xCCU, 0x66U, 0xB3U, 0xE7U, 0x32U, 0x98U, 0x4DU, 0x30U, 0xE5U, 0x4FU, 0x9AU, 0xCEU, 0x1BU, 0xB1U, 0x64U,
        0x72U, 0xA7U, 0x0DU, 0xD8U, 0x8CU, 0x59U, 0xF3U, 0x26U, 0x5BU, 0x8EU, 0x24U, 0xF1U, 0xA5U, 0x70U, 0xDAU, 0x0FU,
        0x20U, 0xF5U, 0x5FU, 0x8AU, 0xDEU, 0x0BU, 0xA1U, 0x74U, 0x09U, 0xDCU, 0x76U, 0xA3U, 0xF7U, 0x22U, 0x88U, 0x5DU,
        0xD6U, 0x03U, 0xA9U, 0x7CU, 0x28U, 0xFDU, 0x57U, 0x82U, 0xFFU, 0x2AU, 0x80U, 0x55U, 0x01U, 0xD4U, 0x7EU, 0xABU,
        0x84U, 0x51U, 0xFBU, 0x2EU, 0x7AU, 0xAFU, 0x05U, 0xD0U, 0xADU, 0x78U, 0xD2U, 0x07U, 0x53U, 0x86U, 0x2CU, 0xF9U
    };

    uint8_t crc_initial_value = INITIAL_CRC8_VALUE;

    if (NULL_PTR != last_crc_ptr) {
        crc_initial_value = *last_crc_ptr;
    }

    return Crc8Base(
               crc_table,
               crc_data_ptr,
               crc_length,
               crc_initial_value,
               FINAL_XOR_VALUE,
               REFLECTED_OUTPUT,
               REFLECTED_INPUT,
               FINAL_XOR
           );
}
