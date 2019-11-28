# STM32-Makefile-English
Build a compile Toolchain using complete open-source tools, including gcc-none-eabi, gnu make, openocd...
This Makefile aims at teaching you how to arrange your projects and compile it to get the right results.

# STM32-Makefile-Simple Chinese
使用完全开源免费的工具搭建STM32开发环境，工具有Gcc、Make、Openocd等。Makefile会告诉你怎么组织项目并且怎样编译以获得正确的结果。

#how to use it(怎样使用）

1. Download the STM32 Standard Peripheral Libraries from the offical website:
  https://www.st.com/en/embedded-software/stm32-standard-peripheral-libraries.html
2. Unpack it and find the ld script, copy it to root directory.
3. Move Makefile、User which ist in examplecode, to the libraries root directory.
4. According to your board modify the content:
   Flash.ld: _estack RAM FLASH CCMRAM
   Makefile: TARGET ARCH MCU Openocd_Interf Openocd_Target LD_FLASH, sometimes need exclude some files.
5. Then connect to your borad, in the above terminal type make && make download

中文教程

1. 从官方网站下载对应的固件库
 https://www.st.com/en/embedded-software/stm32-standard-peripheral-libraries.html
2. 将 固件库解压并放到某一位置，将ld脚本从/Project/xxTemplate/TrueSTUDIO/STMxx/xxFLASH_ld复制到根目录,如果大规模使用，需要自己写个链接脚本
3. 将Makefile 及自己的代码(代码需在User下/User/Projects/your Code）复制到根目录, 如果还有子目录，则需要改动Makeflie。你如果有更好的建议，欢迎告诉我。
4. 重要，修改Flash.ld: _estack RAM FLASH CCMRAM
        修该Makefile: TARGET ARCH MCU Openocd_Interf Openocd_Target LD_FLASH，必要时候一些c文件也要排除在外。
5. 再输入: make && make download
6. 大功告成，欢呼一下。
