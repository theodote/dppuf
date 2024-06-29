/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

//#include <stdio.h>
#include "xparameters.h"
#include "xuartps.h"
#include "platform.h"
//#include "xil_printf.h"
#include "xgpio.h"
#include "sleep.h"

//#define UART_DEVICE_ID	XPAR_XUARTPS_0_DEVICE_ID
#define BUFFER_SIZE			8
#define BYTES_TO_RECEIVE	8	// SHOULD BE 8

typedef union ReadyData {
	u32 Raw;
	struct {
		u16 Data;
		u8 Flag;
		u8 Padding;
	};
} ReadyData;

typedef union InPacket {
	struct {
		u16 Start;
		u16 Stop;
		u16 Step;
		u16 Dppuf;
	};
} InPacket;

void ExceptionHandler(XGpio* DebugLeds) {
	u32 Blinky = 1;
	while (1) {
		XGpio_DiscreteWrite(DebugLeds, 1, Blinky);
		Blinky = Blinky << 1;
		if (Blinky == 0x80000000) Blinky = 1;
		usleep(10000);
	}
}

int main(void)
{
    init_platform();
    int Status;

    // init gpio
    XGpio ToDppuf;
    XGpio_Initialize(&ToDppuf, XPAR_AXI_GPIO_0_DEVICE_ID);		// axi_gpio_0 !!! numbers MUST MATCH IN PL
    XGpio_SetDataDirection(&ToDppuf, 1, 0b00000000);			// 2 channels, but we use 1 -> 1; 1=in,0=out. all outs here

    XGpio FromDppuf;
    XGpio_Initialize(&FromDppuf, XPAR_AXI_GPIO_1_DEVICE_ID);	// axi_gpio_1
    XGpio_SetDataDirection(&FromDppuf, 1, 0b11111111);			// all inputs

    XGpio Leds;
    XGpio_Initialize(&Leds, XPAR_AXI_GPIO_2_DEVICE_ID);			// axi_gpio_2
    XGpio_SetDataDirection(&Leds, 1, 0b00000000);				// all outputs

    XGpio Select;
    XGpio_Initialize(&Select, XPAR_AXI_GPIO_3_DEVICE_ID);		// axi_gpio_3
    XGpio_SetDataDirection(&Select, 1, 0b00000000);				// all outputs

    // init uart, quick self-test
    XUartPs_Config* ConfigUart1;
    XUartPs Uart1;
    static u8 RecvBuffer[BUFFER_SIZE];

    ConfigUart1 = XUartPs_LookupConfig(UART_DEVICE_ID);
    if (ConfigUart1 == NULL) {
    	return XST_DEVICE_NOT_FOUND;
    }
    Status = XUartPs_CfgInitialize(&Uart1, ConfigUart1, ConfigUart1->BaseAddress);
    if (Status != XST_SUCCESS) {
    	return XST_FAILURE;
    }
    Status = XUartPs_SelfTest(&Uart1);
    if (Status != XST_SUCCESS) {
    	return XST_FAILURE;
    }
    XUartPs_SetOperMode(&Uart1, XUARTPS_OPER_MODE_NORMAL);

    ReadyData SendToDppuf, RecvFromDppuf;

    u16 Start, Stop, Step, Dppuf;
    u16 Challenge;

    u8* ResponseBytes = (u8*)(&RecvFromDppuf.Data);
    u8 ResponseXored;

    u8 Sent, TotalSent;
    int UartFails, BytesReceived = 0;

    while (1) {
    	BytesReceived += XUartPs_Recv(&Uart1, (RecvBuffer + (BytesReceived % sizeof(InPacket))), sizeof(InPacket));

    	if (BytesReceived >= sizeof(InPacket)) {
    		Start = RecvBuffer[0] | (RecvBuffer[1] << 8);
    		Stop = RecvBuffer[2] | (RecvBuffer[3] << 8);
    		Step = RecvBuffer[4] | (RecvBuffer[5] << 8);
    		Dppuf = RecvBuffer[6] | (RecvBuffer[7] << 8);

    		XGpio_DiscreteWrite(&Select, 1, (0xFFFFFFFF & Dppuf));

    		for (Challenge = Start; Challenge >= Start; Challenge += Step) {
    			SendToDppuf.Data = Challenge;
    			SendToDppuf.Flag = 0;
    			XGpio_DiscreteWrite(&ToDppuf, 1, SendToDppuf.Raw);
    			SendToDppuf.Flag = 1;
    			XGpio_DiscreteWrite(&ToDppuf, 1, SendToDppuf.Raw);

    			do {
    			    RecvFromDppuf.Raw = XGpio_DiscreteRead(&FromDppuf, 1);
    			} while (!RecvFromDppuf.Flag);

    			SendToDppuf.Flag = 0;	// don't forget to pull it back!
    			XGpio_DiscreteWrite(&ToDppuf, 1, SendToDppuf.Raw);

    			// debug. see if two response bytes are different
    			ResponseXored = ResponseBytes[0] ^ ResponseBytes[1];
    			XGpio_DiscreteWrite(&Leds, 1, (ResponseXored & 0xFFFFFFFF));

    			Sent = TotalSent = 0;
    			UartFails = 0;
    			do {
    				Sent = XUartPs_Send(&Uart1, ((u8*)(&RecvFromDppuf.Data) + TotalSent), 1);
    				if (Sent == 0) {
    					UartFails++;
    					if (UartFails >= 512) {
    						ExceptionHandler(&Leds);
    					}
    				}
    				TotalSent += Sent;
    			} while (TotalSent != sizeof(RecvFromDppuf.Data));

    			if (Stop - Challenge < Step) break;

    		}

    		BytesReceived = 0;
    	}
    }

    cleanup_platform();
    return XST_SUCCESS;
}
