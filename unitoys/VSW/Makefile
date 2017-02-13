SRCS = $(wildcard *.c)
OBJS = $(SRCS:.c = .o)

#KERNEL_DIR:=/home/eric/work/vifi2/openwrt_vifi2/build_dir/target-mipsel_24kec+dsp_uClibc-0.9.33.2/linux-ramips_mt7628/linux-3.10.14-p112871/

CROSS_COMPILE=mipsel-openwrt-linux-uclibc-
CC = $(CROSS_COMPILE)gcc
#INCLUDES = -I/home/noah/build_sqlite3/include
LIBS = -lrt -lpthread
CCFLAGS = -g -Wall -O0

simcom:$(OBJS)
	$(CC)  $^ -o $@ $(INCLUDES) $(LIBS)

%.o:%.c
	$(CC) -c $< $(CCFLAGS)
clean:
	rm *.o

