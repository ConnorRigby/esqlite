ifeq ($(ERL_EI_INCLUDE_DIR),)
$(error ERL_EI_INCLUDE_DIR not set. Invoke via mix)
endif

# Set Erlang-specific compile and linker flags
ERL_CFLAGS ?= -I$(ERL_EI_INCLUDE_DIR)
ERL_LDFLAGS ?= -L$(ERL_EI_LIBDIR)

SRC=$(wildcard c_src/*.c)
OBJ=$(SRC:.c=.o)

LDFLAGS ?= -fPIC -shared -pedantic
CFLAGS ?= -fPIC -O2
SQLITE_CFLAGS = -DSQLITE_THREADSAFE=1 -DSQLITE_USE_URI -DSQLITE_ENABLE_FTS3 \
-DSQLITE_ENABLE_FTS3_PARENTHESIS -DSQLITE_ENABLE_FTS5 -DSQLITE_ENABLE_JSON1 \
-DSQLITE_ENABLE_RTREE

NIF=priv/esqlite3_nif.so

all: priv $(NIF)

priv:
	mkdir -p priv

%.o: %.c
	$(CC) -c $(ERL_CFLAGS) $(CFLAGS) $(SQLITE_CFLAGS) -o $@ $<

$(NIF): $(OBJ)
	$(CC) $^ $(ERL_LDFLAGS) $(LDFLAGS) -o $@

clean:
	$(RM) $(NIF)
	$(RM) $(OBJ)
