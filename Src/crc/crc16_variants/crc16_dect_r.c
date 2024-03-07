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

#include "crc16_dect_r.h"

#include "crc16_base.h"

#define INITIAL_CRC16_VALUE (0x0U)
#define FINAL_XOR_VALUE (0x1U)
#define REFLECTED_OUTPUT (false)
#define REFLECTED_INPUT (false)
#define FINAL_XOR (true)

uint16_t
Crc16_dectR(
    const uint8_t* crc_data_ptr,
    uint32_t crc_length,
    bool final_crc,
    const uint16_t* last_crc_ptr) {

    /* Table for CRC-16 DECT R (Polynomial 0x0589) */
    static const uint16_t crc_table[256] = {
        0x0000U, 0x0589U, 0x0B12U, 0x0E9BU, 0x1624U, 0x13ADU, 0x1D36U, 0x18BFU, 0x2C48U, 0x29C1U, 0x275AU, 0x22D3U, 0x3A6CU, 0x3FE5U, 0x317EU, 0x34F7U,
        0x5890U, 0x5D19U, 0x5382U, 0x560BU, 0x4EB4U, 0x4B3DU, 0x45A6U, 0x402FU, 0x74D8U, 0x7151U, 0x7FCAU, 0x7A43U, 0x62FCU, 0x6775U, 0x69EEU, 0x6C67U,
        0xB120U, 0xB4A9U, 0xBA32U, 0xBFBBU, 0xA704U, 0xA28DU, 0xAC16U, 0xA99FU, 0x9D68U, 0x98E1U, 0x967AU, 0x93F3U, 0x8B4CU, 0x8EC5U, 0x805EU, 0x85D7U,
        0xE9B0U, 0xEC39U, 0xE2A2U, 0xE72BU, 0xFF94U, 0xFA1DU, 0xF486U, 0xF10FU, 0xC5F8U, 0xC071U, 0xCEEAU, 0xCB63U, 0xD3DCU, 0xD655U, 0xD8CEU, 0xDD47U,
        0x67C9U, 0x6240U, 0x6CDBU, 0x6952U, 0x71EDU, 0x7464U, 0x7AFFU, 0x7F76U, 0x4B81U, 0x4E08U, 0x4093U, 0x451AU, 0x5DA5U, 0x582CU, 0x56B7U, 0x533EU,
        0x3F59U, 0x3AD0U, 0x344BU, 0x31C2U, 0x297DU, 0x2CF4U, 0x226FU, 0x27E6U, 0x1311U, 0x1698U, 0x1803U, 0x1D8AU, 0x0535U, 0x00BCU, 0x0E27U, 0x0BAEU,
        0xD6E9U, 0xD360U, 0xDDFBU, 0xD872U, 0xC0CDU, 0xC544U, 0xCBDFU, 0xCE56U, 0xFAA1U, 0xFF28U, 0xF1B3U, 0xF43AU, 0xEC85U, 0xE90CU, 0xE797U, 0xE21EU,
        0x8E79U, 0x8BF0U, 0x856BU, 0x80E2U, 0x985DU, 0x9DD4U, 0x934FU, 0x96C6U, 0xA231U, 0xA7B8U, 0xA923U, 0xACAAU, 0xB415U, 0xB19CU, 0xBF07U, 0xBA8EU,
        0xCF92U, 0xCA1BU, 0xC480U, 0xC109U, 0xD9B6U, 0xDC3FU, 0xD2A4U, 0xD72DU, 0xE3DAU, 0xE653U, 0xE8C8U, 0xED41U, 0xF5FEU, 0xF077U, 0xFEECU, 0xFB65U,
        0x9702U, 0x928BU, 0x9C10U, 0x9999U, 0x8126U, 0x84AFU, 0x8A34U, 0x8FBDU, 0xBB4AU, 0xBEC3U, 0xB058U, 0xB5D1U, 0xAD6EU, 0xA8E7U, 0xA67CU, 0xA3F5U,
        0x7EB2U, 0x7B3BU, 0x75A0U, 0x7029U, 0x6896U, 0x6D1FU, 0x6384U, 0x660DU, 0x52FAU, 0x5773U, 0x59E8U, 0x5C61U, 0x44DEU, 0x4157U, 0x4FCCU, 0x4A45U,
        0x2622U, 0x23ABU, 0x2D30U, 0x28B9U, 0x3006U, 0x358FU, 0x3B14U, 0x3E9DU, 0x0A6AU, 0x0FE3U, 0x0178U, 0x04F1U, 0x1C4EU, 0x19C7U, 0x175CU, 0x12D5U,
        0xA85BU, 0xADD2U, 0xA349U, 0xA6C0U, 0xBE7FU, 0xBBF6U, 0xB56DU, 0xB0E4U, 0x8413U, 0x819AU, 0x8F01U, 0x8A88U, 0x9237U, 0x97BEU, 0x9925U, 0x9CACU,
        0xF0CBU, 0xF542U, 0xFBD9U, 0xFE50U, 0xE6EFU, 0xE366U, 0xEDFDU, 0xE874U, 0xDC83U, 0xD90AU, 0xD791U, 0xD218U, 0xCAA7U, 0xCF2EU, 0xC1B5U, 0xC43CU,
        0x197BU, 0x1CF2U, 0x1269U, 0x17E0U, 0x0F5FU, 0x0AD6U, 0x044DU, 0x01C4U, 0x3533U, 0x30BAU, 0x3E21U, 0x3BA8U, 0x2317U, 0x269EU, 0x2805U, 0x2D8CU,
        0x41EBU, 0x4462U, 0x4AF9U, 0x4F70U, 0x57CFU, 0x5246U, 0x5CDDU, 0x5954U, 0x6DA3U, 0x682AU, 0x66B1U, 0x6338U, 0x7B87U, 0x7E0EU, 0x7095U, 0x751CU
    };

    bool final_xor = false;
    uint16_t crc_initial_value = INITIAL_CRC16_VALUE;

    if (NULL_PTR != last_crc_ptr) {
        crc_initial_value = *last_crc_ptr;
    }

    if (final_crc) {
        final_xor = FINAL_XOR;
    }

    return Crc16Base(
               crc_table,
               crc_data_ptr,
               crc_length,
               crc_initial_value,
               FINAL_XOR_VALUE,
               REFLECTED_OUTPUT,
               REFLECTED_INPUT,
               final_xor
           );
}
