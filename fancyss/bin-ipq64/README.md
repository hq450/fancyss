# Binary for IPQ64 platform

华硕TUF-BE6500采用了高通IPQ5322处理器，其固件为全64位固件，编译工具链为：`openwrt-gcc750_musl1124.aarch64`，由于固件内没有相关32位的库，所以很多能在`BD4`上运行的32位二进制无法在`TUF-BE6500`运行

目前高通64位的二进制理论上需要使用`openwrt-gcc750_musl1124.aarch64`编译，但是此工具链与华硕天选TX-AX6000的工具链`openwrt-gcc840_musl.aarch64`是同一类，所以能在TX-AX6000上运行的二进制基本上能在TUF-BE6500上运行。

