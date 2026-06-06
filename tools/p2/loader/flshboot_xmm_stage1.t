{
Tiny P2 SPI-flash boot stage for Catalina XMM images.

The P2 ROM loads this first 1024-byte block from flash address 0. It copies a
size-prefixed second-stage loader from flash address $1_0000 into Hub RAM and
starts it at Hub address 0. The second stage then copies the Catalina XMM image
from flash into Hub/PSRAM and starts the Catalina XMM hub loader.
}

con
        crystal = 20_000_000
        dv = 40
        mlt = 360
        clk = 1 << 24 | (dv-1) << 18 | (mlt-1) << 8

        spi_do = 58
        spi_di = 59
        spi_clk = 60
        spi_cs = 61

        read_data = 3
        loader_flash_addr = $1_0000

dat     org

stage1
        hubset  ##clk & $FFFFFFFC
        hubset  #0
        hubset  ##clk | %1111_01_00
        waitx   ##20_000_000/100
        hubset  ##clk | %1111_01_11

        drvh    #spi_cs
        drvl    #spi_clk
        drvl    #spi_di

        mov     pb,##loader_flash_addr
        mov     ptra,#0
        outl    #spi_cs
        callpa  #read_data,#send_byte

        getbyte pa,pb,#2
        call    #send_byte
        getbyte pa,pb,#1
        call    #send_byte
        getbyte pa,pb,#0
        call    #send_byte

        call    #read_byte
        call    #read_byte
        call    #read_byte
        call    #read_byte
        movbyts pa,#%%0123

        mov     pb,pa
.loop   call    #read_byte
        wrbyte  pa,ptra++
        djnz    pb,#.loop

        outh    #spi_cs
        coginit #0,#0

send_byte
        rep @.loop,#8
        testb   pa,#7 wc
        outc    #spi_di
        outh    #spi_clk
        outl    #spi_clk
        shl     pa,#1
.loop
        ret

read_byte
        rep @.loop,#8
        outh    #spi_clk
        outl    #spi_clk
        testp   #spi_do wc
        rcl     pa,#1
.loop
        ret

        orgf    $100
