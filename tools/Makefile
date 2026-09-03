# Builds the headless tools: the balance simulator and the text playtest.
CXX ?= g++
CXXFLAGS ?= -std=c++17 -Wall -Wextra -Werror -O2
SIM := ../sim
SIM_SOURCES := $(SIM)/src/json.cpp $(SIM)/src/tuning.cpp $(SIM)/src/economy.cpp \
               $(SIM)/src/items.cpp $(SIM)/src/boons.cpp $(SIM)/src/stats.cpp \
               $(SIM)/src/combat.cpp $(SIM)/src/trial.cpp $(SIM)/src/save.cpp $(SIM)/src/worldgen.cpp $(SIM)/src/loot.cpp $(SIM)/src/grammar.cpp $(SIM)/src/lattice.cpp $(SIM)/src/encroachment.cpp $(SIM)/src/foundry.cpp

.PHONY: all balance playtest clean
all: build/balance build/playtest

build/balance: balance/balance_main.cpp $(SIM_SOURCES) $(wildcard $(SIM)/include/wroughtwild/*.h)
	@mkdir -p build
	$(CXX) $(CXXFLAGS) -I$(SIM)/include balance/balance_main.cpp $(SIM_SOURCES) -o $@

build/playtest: playtest/playtest_main.cpp $(SIM_SOURCES) $(wildcard $(SIM)/include/wroughtwild/*.h)
	@mkdir -p build
	$(CXX) $(CXXFLAGS) -I$(SIM)/include playtest/playtest_main.cpp $(SIM_SOURCES) -o $@

balance: build/balance
	./build/balance ../data/tuning

clean:
	rm -rf build
