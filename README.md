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

+ 串口 stage5 2016.11.29 llylly
+ Flash stage5 2016.11.29 llylly
+ UCore移植 stage5 2016.12.3 llylly
+ UCore代码测试 stage5 2016.12.3 llylly

	2016.12.3 成功上板并进入用户态

+ 键盘 stage6 2016.12.11 llylly
+ VGA显示 stage6 2016.12.11 llylly

	还修复了一些重要的BUG

+ WishBone --Discard
+ Decaf移植 (half) gaoty

#### 说明

+ trans.cpp

	用来将.mem格式文本初始化文件转换成真正的二进制文件

+ ucore11.data ucore11.mem

	这是一个进行了修改：
	
	- 红黑树大小调到了100个节点
	- sh为了加速输入，直接从串口读
	- 内存大小设为7M，剩下1M留给硬盘
	- 编译了20+个用户态程序
	
	的操作系统

+ booter.c booter.mem booter.s

	重写的BIOS，因为本人看见ELF头会非常不高兴，所以不能用喜欢ELF头的BIOS，于是自己造了个BIOS

+ bin2mem.cpp bin2membig.cpp

	将二进制文件转换为.mem文本初始化文件的工具，前者是用于大端的，后者是用于小端的（注意：和命名相反）

使用这个cpu的方法：先编译uCore，编译好了将initrd用bin2membig转成内存初始化文件，再删去前24行（ELF头），将重命名为user.mem使用trans转为user.data文件，再将user.data从0地址开始烧入flash，就可以了

#### Feature
	
+ 我把串口和键盘并在了一起，统一通过BFD003F8, BFD003FC访问，这样就没有了键盘中断，也不需要改uCore。缺陷是硬件实现的键盘处理模块有缺陷，按的太快会因为前一个键没有释放的原因，判断出错。