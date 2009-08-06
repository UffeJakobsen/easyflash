/*
 * EasyProg - torturetest.c - Torture Test
 *
 * (c) 2009 Thomas Giesel
 *
 * This software is provided 'as-is', without any express or implied
 * warranty.  In no event will the authors be held liable for any damages
 * arising from the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software
 *    in a product, an acknowledgment in the product documentation would be
 *    appreciated but is not required.
 * 2. Altered source versions must be plainly marked as such, and must not be
 *    misrepresented as being the original software.
 * 3. This notice may not be removed or altered from any source distribution.
 *
 * Thomas Giesel skoe@directbox.com
 */

#include <stdio.h>

#include "screen.h"
#include "easyprog.h"
#include "torturetest.h"
#include "flash.h"

/*
 * The cartridge test works like this:
 * - Each bank (8 KiB) is filled with a special pattern:
 *   2k bank number
 *   2k 0xaa
 *   2k 0x55
 *   1k 0x00 - 0xff (repeated)
 *   1k 0xff - 0x00 (repeated)
 */

// static because my heap doesn't work yet
// The buffer must always be 256 bytes long
static uint8_t buffer[256];

/******************************************************************************/
/**
 * Write the test data to the cartridge.
 *
 * return 1 for success, 0 for failure
 */
static uint8_t tortureTestWriteData(void)
{
    EasyFlashAddr addr;

    for (addr.nBank = 0; addr.nBank < FLASH_NUM_BANKS; ++addr.nBank)
    {
        for (addr.nChip = 0; addr.nChip < 2; ++addr.nChip)
        {
            for (addr.nOffset = 0; addr.nOffset < 0x2000; addr.nOffset += 256)
            {
                tortureTestFillBuffer(buffer, &addr);

                if (!flashWriteBlock(addr.nBank, addr.nChip, addr.nOffset,
                                     buffer))
                {
                    return 0;
                }
            }
        }
    }

    return 1;
}

/******************************************************************************/
/**
 * Verify the test data on the cartridge.
 *
 * return 1 for success, 0 for failure
 */
static uint8_t tortureTestVerify(void)
{
    char            strStatus[41];
    EasyFlashAddr   addr;
    uint16_t        rv;
    uint8_t         nData;
    uint8_t         nFlash;

    for (addr.nBank = 0; addr.nBank < FLASH_NUM_BANKS; ++addr.nBank)
    {
        for (addr.nChip = 0; addr.nChip < 2; ++addr.nChip)
        {
            for (addr.nOffset = 0; addr.nOffset < 0x2000; addr.nOffset += 256)
            {
                tortureTestFillBuffer(buffer, &addr);

                rv = tortureTestCompare(buffer, &addr);

                if (rv != 256)
                {
                    nData = buffer[rv];
                    if (addr.nChip)
                        nFlash = ROM1_BASE[addr.nOffset + rv];
                    else
                        nFlash = ROM0_BASE[addr.nOffset + rv];

                    screenPrintVerifyError(addr.nBank, addr.nChip, addr.nOffset + rv,
                                           nData, nFlash);
                    return 0;
                }
            }
        }
    }

    return 1;
}

void tortureTest(void)
{
    char strStatus[41];
    uint16_t rv;
    uint16_t nLoop;

    refreshMainScreen();

    tortureTestWriteData();

    for (nLoop = 0; ; ++nLoop)
    {
        sprintf(strStatus, "Test loop %u", nLoop);
        setStatus(strStatus);

        rv = tortureTestBanking();
        if (rv != 0)
        {
            sprintf(strStatus, "Bank test error: set %02X != read %02X",
                    rv >> 8, rv & 0xff);

            screenPrintTwoLinesDialog("Test failed", strStatus);
            return;
        }

        if (!tortureTestVerify())
            return;
    }
}
