# Headless simulation-core tests. Usage: make (builds and runs).
CXX ?= g++
CXXFLAGS ?= -std=c++17 -Wall -Wextra -Werror -O1
SIM := ../../sim
SOURCES := test_main.cpp $(SIM)/src/json.cpp $(SIM)/src/tuning.cpp \
           $(SIM)/src/economy.cpp $(SIM)/src/items.cpp $(SIM)/src/boons.cpp \
           $(SIM)/src/stats.cpp $(SIM)/src/combat.cpp $(SIM)/src/trial.cpp \
           $(SIM)/src/save.cpp $(SIM)/src/worldgen.cpp $(SIM)/src/worldgen_profiles.cpp $(SIM)/src/loot.cpp $(SIM)/src/grammar.cpp $(SIM)/src/lattice.cpp $(SIM)/src/foundry.cpp $(SIM)/src/daycycle.cpp
BIN := build/sim_tests

.PHONY: test world-intensive strange-frontier cataclysm-world pressure-generation wide-frontier worldgen-kernels contraptions clean
test: $(BIN)
	./$(BIN) ../../data/tuning

# Complete terrain/pack fingerprints from before the intensive, multi-seed
# reachable habitat guarantees, and the approved material/form matrix.
world-intensive: build/world_intensive_tests
	./build/world_intensive_tests ../../data/tuning

strange-frontier: build/strange_frontier_tests
	./build/strange_frontier_tests ../../data/tuning

cataclysm-world: build/cataclysm_world_tests
	./build/cataclysm_world_tests ../../data/tuning

build/cataclysm_world_tests: test_cataclysm_world.cpp test_strange_frontier.cpp worldgen_history.inc $(SIM)/src/worldgen.cpp $(SIM)/src/worldgen_profiles.cpp $(wildcard $(SIM)/src/worldgen_*.inc) $(SIM)/src/tuning.cpp $(SIM)/src/json.cpp $(SIM)/src/lattice.cpp $(wildcard $(SIM)/include/wroughtwild/*.h)
	@mkdir -p build
	$(CXX) $(CXXFLAGS) -I$(SIM)/include test_cataclysm_world.cpp $(SIM)/src/worldgen.cpp $(SIM)/src/worldgen_profiles.cpp $(SIM)/src/tuning.cpp $(SIM)/src/json.cpp $(SIM)/src/lattice.cpp -o $@

pressure-generation: build/pressure_generation_tests
	./build/pressure_generation_tests ../../data/tuning

wide-frontier: build/wide_frontier_tests
	./build/wide_frontier_tests ../../data/tuning

worldgen-kernels: build/worldgen_kernel_tests
	./build/worldgen_kernel_tests

build/worldgen_kernel_tests: test_worldgen_kernels.cpp $(SIM)/src/worldgen.cpp $(SIM)/src/worldgen_profiles.cpp $(wildcard $(SIM)/src/worldgen_*.inc) $(SIM)/src/tuning.cpp $(SIM)/src/json.cpp $(SIM)/src/lattice.cpp $(wildcard $(SIM)/include/wroughtwild/*.h)
	@mkdir -p build
	$(CXX) $(CXXFLAGS) -I$(SIM)/include test_worldgen_kernels.cpp $(SIM)/src/worldgen.cpp $(SIM)/src/tuning.cpp $(SIM)/src/json.cpp $(SIM)/src/lattice.cpp -o $@

build/worldgen_performance: worldgen_performance.cpp worldgen_fingerprint.inc $(SIM)/src/worldgen.cpp $(SIM)/src/worldgen_profiles.cpp $(wildcard $(SIM)/src/worldgen_*.inc) $(SIM)/src/tuning.cpp $(SIM)/src/json.cpp $(SIM)/src/lattice.cpp $(wildcard $(SIM)/include/wroughtwild/*.h)
	@mkdir -p build
	$(CXX) $(CXXFLAGS) -I$(SIM)/include worldgen_performance.cpp $(SIM)/src/worldgen.cpp $(SIM)/src/worldgen_profiles.cpp $(SIM)/src/tuning.cpp $(SIM)/src/json.cpp $(SIM)/src/lattice.cpp -o $@

build/wide_frontier_tests: test_wide_frontier.cpp test_strange_frontier.cpp worldgen_history.inc $(SIM)/src/worldgen.cpp $(SIM)/src/worldgen_profiles.cpp $(wildcard $(SIM)/src/worldgen_*.inc) $(SIM)/src/tuning.cpp $(SIM)/src/json.cpp $(SIM)/src/lattice.cpp $(wildcard $(SIM)/include/wroughtwild/*.h)
	@mkdir -p build
	$(CXX) $(CXXFLAGS) -I$(SIM)/include test_wide_frontier.cpp $(SIM)/src/worldgen.cpp $(SIM)/src/worldgen_profiles.cpp $(SIM)/src/tuning.cpp $(SIM)/src/json.cpp $(SIM)/src/lattice.cpp -o $@

build/pressure_generation_tests: test_pressure_generation.cpp test_strange_frontier.cpp worldgen_history.inc $(SIM)/src/worldgen.cpp $(SIM)/src/worldgen_profiles.cpp $(wildcard $(SIM)/src/worldgen_*.inc) $(SIM)/src/tuning.cpp $(SIM)/src/json.cpp $(SIM)/src/lattice.cpp $(wildcard $(SIM)/include/wroughtwild/*.h)
	@mkdir -p build
	$(CXX) $(CXXFLAGS) -I$(SIM)/include test_pressure_generation.cpp $(SIM)/src/worldgen.cpp $(SIM)/src/worldgen_profiles.cpp $(SIM)/src/tuning.cpp $(SIM)/src/json.cpp $(SIM)/src/lattice.cpp -o $@

build/strange_frontier_tests: test_strange_frontier.cpp $(SIM)/src/worldgen.cpp $(SIM)/src/worldgen_profiles.cpp $(wildcard $(SIM)/src/worldgen_*.inc) $(SIM)/src/tuning.cpp $(SIM)/src/json.cpp $(SIM)/src/lattice.cpp $(wildcard $(SIM)/include/wroughtwild/*.h)
	@mkdir -p build
	$(CXX) $(CXXFLAGS) -I$(SIM)/include test_strange_frontier.cpp $(SIM)/src/worldgen.cpp $(SIM)/src/worldgen_profiles.cpp $(SIM)/src/tuning.cpp $(SIM)/src/json.cpp $(SIM)/src/lattice.cpp -o $@

contraptions: build/contraption_tests
	./build/contraption_tests ../../data/tuning

build/contraption_tests: test_contraptions.cpp $(SIM)/src/contraptions.cpp $(SIM)/src/json.cpp $(SIM)/include/wroughtwild/contraptions.h
	@mkdir -p build
	$(CXX) $(CXXFLAGS) -I$(SIM)/include test_contraptions.cpp $(SIM)/src/contraptions.cpp $(SIM)/src/json.cpp -o $@

build/world_intensive_tests: test_world_intensive.cpp $(SIM)/src/worldgen.cpp $(SIM)/src/worldgen_profiles.cpp $(wildcard $(SIM)/src/worldgen_*.inc) $(SIM)/src/tuning.cpp $(SIM)/src/json.cpp $(SIM)/src/lattice.cpp $(wildcard $(SIM)/include/wroughtwild/*.h)
	@mkdir -p build
	$(CXX) $(CXXFLAGS) -I$(SIM)/include test_world_intensive.cpp $(SIM)/src/worldgen.cpp $(SIM)/src/worldgen_profiles.cpp $(SIM)/src/tuning.cpp $(SIM)/src/json.cpp $(SIM)/src/lattice.cpp -o $@

$(BIN): $(SOURCES) trial_intensive.h material_intensive.inc $(wildcard $(SIM)/src/worldgen_*.inc) $(wildcard $(SIM)/include/wroughtwild/*.h)
	@mkdir -p build
	$(CXX) $(CXXFLAGS) -I$(SIM)/include $(SOURCES) -o $(BIN)

clean:
	rm -rf build
