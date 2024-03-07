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

#include "crc16_teledisk.h"

#include "crc16_base.h"

#define INITIAL_CRC16_VALUE (0x0U)
#define FINAL_XOR_VALUE (0x0U)
#define REFLECTED_OUTPUT (false)
#define REFLECTED_INPUT (false)
#define FINAL_XOR (false)

uint16_t
Crc16_teledisk(
    const uint8_t* crc_data_ptr,
    uint32_t crc_length,
    const uint16_t* last_crc_ptr) {

    /* Table for CRC-16 TELEDISK (Polynomial 0xA097) */
    static const uint16_t crc_table[256] = {
        0x0000U, 0xA097U, 0xE1B9U, 0x412EU, 0x63E5U, 0xC372U, 0x825CU, 0x22CBU, 0xC7CAU, 0x675DU, 0x2673U, 0x86E4U, 0xA42FU, 0x04B8U, 0x4596U, 0xE501U,
        0x2F03U, 0x8F94U, 0xCEBAU, 0x6E2DU, 0x4CE6U, 0xEC71U, 0xAD5FU, 0x0DC8U, 0xE8C9U, 0x485EU, 0x0970U, 0xA9E7U, 0x8B2CU, 0x2BBBU, 0x6A95U, 0xCA02U,
        0x5E06U, 0xFE91U, 0xBFBFU, 0x1F28U, 0x3DE3U, 0x9D74U, 0xDC5AU, 0x7CCDU, 0x99CCU, 0x395BU, 0x7875U, 0xD8E2U, 0xFA29U, 0x5ABEU, 0x1B90U, 0xBB07U,
        0x7105U, 0xD192U, 0x90BCU, 0x302BU, 0x12E0U, 0xB277U, 0xF359U, 0x53CEU, 0xB6CFU, 0x1658U, 0x5776U, 0xF7E1U, 0xD52AU, 0x75BDU, 0x3493U, 0x9404U,
        0xBC0CU, 0x1C9BU, 0x5DB5U, 0xFD22U, 0xDFE9U, 0x7F7EU, 0x3E50U, 0x9EC7U, 0x7BC6U, 0xDB51U, 0x9A7FU, 0x3AE8U, 0x1823U, 0xB8B4U, 0xF99AU, 0x590DU,
        0x930FU, 0x3398U, 0x72B6U, 0xD221U, 0xF0EAU, 0x507DU, 0x1153U, 0xB1C4U, 0x54C5U, 0xF452U, 0xB57CU, 0x15EBU, 0x3720U, 0x97B7U, 0xD699U, 0x760EU,
        0xE20AU, 0x429DU, 0x03B3U, 0xA324U, 0x81EFU, 0x2178U, 0x6056U, 0xC0C1U, 0x25C0U, 0x8557U, 0xC479U, 0x64EEU, 0x4625U, 0xE6B2U, 0xA79CU, 0x070BU,
        0xCD09U, 0x6D9EU, 0x2CB0U, 0x8C27U, 0xAEECU, 0x0E7BU, 0x4F55U, 0xEFC2U, 0x0AC3U, 0xAA54U, 0xEB7AU, 0x4BEDU, 0x6926U, 0xC9B1U, 0x889FU, 0x2808U,
        0xD88FU, 0x7818U, 0x3936U, 0x99A1U, 0xBB6AU, 0x1BFDU, 0x5AD3U, 0xFA44U, 0x1F45U, 0xBFD2U, 0xFEFCU, 0x5E6BU, 0x7CA0U, 0xDC37U, 0x9D19U, 0x3D8EU,
        0xF78CU, 0x571BU, 0x1635U, 0xB6A2U, 0x9469U, 0x34FEU, 0x75D0U, 0xD547U, 0x3046U, 0x90D1U, 0xD1FFU, 0x7168U, 0x53A3U, 0xF334U, 0xB21AU, 0x128DU,
        0x8689U, 0x261EU, 0x6730U, 0xC7A7U, 0xE56CU, 0x45FBU, 0x04D5U, 0xA442U, 0x4143U, 0xE1D4U, 0xA0FAU, 0x006DU, 0x22A6U, 0x8231U, 0xC31FU, 0x6388U,
        0xA98AU, 0x091DU, 0x4833U, 0xE8A4U, 0xCA6FU, 0x6AF8U, 0x2BD6U, 0x8B41U, 0x6E40U, 0xCED7U, 0x8FF9U, 0x2F6EU, 0x0DA5U, 0xAD32U, 0xEC1CU, 0x4C8BU,
        0x6483U, 0xC414U, 0x853AU, 0x25ADU, 0x0766U, 0xA7F1U, 0xE6DFU, 0x4648U, 0xA349U, 0x03DEU, 0x42F0U, 0xE267U, 0xC0ACU, 0x603BU, 0x2115U, 0x8182U,
        0x4B80U, 0xEB17U, 0xAA39U, 0x0AAEU, 0x2865U, 0x88F2U, 0xC9DCU, 0x694BU, 0x8C4AU, 0x2CDDU, 0x6DF3U, 0xCD64U, 0xEFAFU, 0x4F38U, 0x0E16U, 0xAE81U,
        0x3A85U, 0x9A12U, 0xDB3CU, 0x7BABU, 0x5960U, 0xF9F7U, 0xB8D9U, 0x184EU, 0xFD4FU, 0x5DD8U, 0x1CF6U, 0xBC61U, 0x9EAAU, 0x3E3DU, 0x7F13U, 0xDF84U,
        0x1586U, 0xB511U, 0xF43FU, 0x54A8U, 0x7663U, 0xD6F4U, 0x97DAU, 0x374DU, 0xD24CU, 0x72DBU, 0x33F5U, 0x9362U, 0xB1A9U, 0x113EU, 0x5010U, 0xF087U
    };

    uint16_t crc_initial_value = INITIAL_CRC16_VALUE;

    if (NULL_PTR != last_crc_ptr) {
        crc_initial_value = *last_crc_ptr;
    }

    return Crc16Base(
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
