### Samming CPU

+ 流水线结构 stage0 2016.10.30 llylly
+ 数据旁路 stage0 2016.10.30 llylly
+ 逻辑、移位、空指令 stage0 2016.10.30 llylly
+ 移动操作指令 stage1 2016.11.2 llylly
+ 单周期算术指令 stage1 2016.11.5 llylly
+ 乘加、乘减与流水线暂停 stage1 2016.11.5 llylly
+ 除法 stage2 2016.11.11 llylly

	当前div结果重算后并不马上清零，以免stall时间因其他原因过长时，结果被清零，导致最后计算值出错

+ 分支与控制冒险 stage2 2016.11.12 llylly
+ 访存 stage2 2016.11.13 llylly

	采用小端方式实现lwl, lwr, swl, swr指令。

+ RAM stage2 2016.11.13 llylly
	
	在sopc上，通过ram_adapter连接ram，控制sram，在宏定义为REAL时，sram信号被引出，否则信号引向仿真sram。

	NOTICE: 只是实现，尚未调试


+ CP0 stage3 2016.11.18 llylly

	气泡已加


+ 异常处理 stage3 2016.11.19 llylly

	添加了Ebase寄存器，用于作为启动异常向量地址寄存器

+ MMU stage4 2016.11.27 llylly

	通过UCore仿真于2016.11.27

+ 串口 2016.11.29 llylly
+ Flash 2016.11.29 llylly
+ UCore移植 2016.12.3 llylly
+ UCore代码测试 2016.12.3 llylly

	2016.12.3 成功上板并进入用户态

+ 键盘 TODO
+ VGA显示 TODO
+ WishBone TODO
+ Decaf移植 TODO