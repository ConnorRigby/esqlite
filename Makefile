ifeq ($(ERL_EI_INCLUDE_DIR),)
$(error ERL_EI_INCLUDE_DIR not set. Invoke via mix)
endif

ifeq ($(ERL_EI_LIBDIR),)
$(error ERL_EI_LIBDIR not set. Invoke via mix)
endif


# Set Erlang-specific compile and linker flags
ERL_CFLAGS ?= -I$(ERL_EI_INCLUDE_DIR)
ERL_LDFLAGS ?= -L$(ERL_EI_LIBDIR) -lei

SRC = $(wildcard c_src/*.c)

LDFLAGS ?= -fPIC -shared -pedantic

CFLAGS ?= -fPIC -O2
SQLITE_CFLAGS = -DSQLITE_THREADSAFE=1 -DSQLITE_USE_URI -DSQLITE_ENABLE_FTS3 \
-DSQLITE_ENABLE_FTS3_PARENTHESIS -DSQLITE_ENABLE_FTS5 -DSQLITE_ENABLE_JSON1 \
-DSQLITE_ENABLE_RTREE

# ESQLITE_USE_SYSTEM - Use the system sqlite3 library
#   Set this ENV var to compile/link against the system sqlite3 library.
#   This is necessary if other applications are accessing the same sqlite db
#   as the versions must match exactly

ifdef ESQLITE_USE_SYSTEM
	CFLAGS += -fPIC
	LDFLAGS += -fPIC -shared -pedantic -lsqlite3
else
	SRC += $(wildcard c_src/sqlite3/*.c)
	CFLAGS += $(SQLITE_CFLAGS) -fPIC -Ic_src/sqlite3
endif

OBJ = $(SRC:.c=.o)

NIF=priv/esqlite3_nif.so

all: priv $(NIF)

priv:
	mkdir -p priv

%.o: %.c
	$(CC) -c $(ERL_CFLAGS) $(CFLAGS) -o $@ $<

$(NIF): $(OBJ)
	$(CC) $^ $(ERL_LDFLAGS) $(LDFLAGS) -o $@

clean:
	$(RM) $(NIF)
	$(RM) $(OBJ)
