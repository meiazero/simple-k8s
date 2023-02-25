PXX = /usr/bin/sh
SRC = src/script.sh
EXEC = main

all: $(EXEC)

$(EXEC): 
	@$(PXX) $(SRC)
