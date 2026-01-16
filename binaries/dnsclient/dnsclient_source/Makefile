CC ?= gcc
CFLAGS ?= -Os -Wall
LDFLAGS ?=

SRC = client.c request.c response.c query.c

dnsclient: $(SRC)
	$(CC) $(CFLAGS) -o $@ $(SRC) $(LDFLAGS)

clean:
	rm -f dnsclient *.o
