# Headless simulation-core tests. Usage: make (builds and runs).
CXX ?= g++
CXXFLAGS ?= -std=c++17 -Wall -Wextra -Werror -O1
SIM := ../../sim
SOURCES := test_main.cpp $(SIM)/src/json.cpp $(SIM)/src/tuning.cpp \
           $(SIM)/src/economy.cpp $(SIM)/src/items.cpp $(SIM)/src/boons.cpp \
           $(SIM)/src/stats.cpp $(SIM)/src/combat.cpp $(SIM)/src/trial.cpp \
           $(SIM)/src/save.cpp $(SIM)/src/worldgen.cpp $(SIM)/src/loot.cpp $(SIM)/src/grammar.cpp
BIN := build/sim_tests

.PHONY: test clean
test: $(BIN)
	./$(BIN) ../../data/tuning

$(BIN): $(SOURCES) $(wildcard $(SIM)/include/wroughtwild/*.h)
	@mkdir -p build
	$(CXX) $(CXXFLAGS) -I$(SIM)/include $(SOURCES) -o $(BIN)

clean:
	rm -rf build
