# Headless simulation-core tests. Usage: make (builds and runs).
CXX ?= g++
CXXFLAGS ?= -std=c++17 -Wall -Wextra -Werror -O1
SIM := ../../sim
SOURCES := test_main.cpp $(SIM)/src/json.cpp $(SIM)/src/tuning.cpp \
           $(SIM)/src/economy.cpp $(SIM)/src/items.cpp $(SIM)/src/boons.cpp \
           $(SIM)/src/stats.cpp $(SIM)/src/combat.cpp $(SIM)/src/trial.cpp \
           $(SIM)/src/save.cpp $(SIM)/src/worldgen.cpp $(SIM)/src/worldgen_profiles.cpp $(SIM)/src/loot.cpp $(SIM)/src/grammar.cpp $(SIM)/src/lattice.cpp $(SIM)/src/foundry.cpp $(SIM)/src/daycycle.cpp
BIN := build/sim_tests

.PHONY: test world-intensive clean
test: $(BIN)
	./$(BIN) ../../data/tuning

# Complete terrain/pack fingerprints from before the intensive, multi-seed
# reachable habitat guarantees, and the approved material/form matrix.
world-intensive: build/world_intensive_tests
	./build/world_intensive_tests ../../data/tuning

build/world_intensive_tests: test_world_intensive.cpp $(SIM)/src/worldgen.cpp $(SIM)/src/worldgen_profiles.cpp $(SIM)/src/worldgen_legacy_v1.inc $(SIM)/src/tuning.cpp $(SIM)/src/json.cpp $(SIM)/src/lattice.cpp $(wildcard $(SIM)/include/wroughtwild/*.h)
	@mkdir -p build
	$(CXX) $(CXXFLAGS) -I$(SIM)/include test_world_intensive.cpp $(SIM)/src/worldgen.cpp $(SIM)/src/worldgen_profiles.cpp $(SIM)/src/tuning.cpp $(SIM)/src/json.cpp $(SIM)/src/lattice.cpp -o $@

$(BIN): $(SOURCES) trial_intensive.h material_intensive.inc $(SIM)/src/worldgen_legacy_v1.inc $(wildcard $(SIM)/include/wroughtwild/*.h)
	@mkdir -p build
	$(CXX) $(CXXFLAGS) -I$(SIM)/include $(SOURCES) -o $(BIN)

clean:
	rm -rf build
