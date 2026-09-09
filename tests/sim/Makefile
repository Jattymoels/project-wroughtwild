# Headless simulation-core tests. Usage: make (builds and runs).
CXX ?= g++
CXXFLAGS ?= -std=c++17 -Wall -Wextra -Werror -O1
SIM := ../../sim
SOURCES := test_main.cpp $(SIM)/src/json.cpp $(SIM)/src/tuning.cpp \
           $(SIM)/src/economy.cpp $(SIM)/src/items.cpp $(SIM)/src/boons.cpp \
           $(SIM)/src/stats.cpp $(SIM)/src/combat.cpp $(SIM)/src/trial.cpp \
           $(SIM)/src/save.cpp $(SIM)/src/resonance.cpp $(SIM)/src/worldgen.cpp $(SIM)/src/worldgen_profiles.cpp $(SIM)/src/loot.cpp $(SIM)/src/grammar.cpp $(SIM)/src/lattice.cpp $(SIM)/src/foundry.cpp $(SIM)/src/daycycle.cpp
BIN := build/sim_tests
.DEFAULT_GOAL := test

.PHONY: test leyline world-intensive strange-frontier cataclysm-world pressure-generation wide-frontier worldgen-kernels contraptions clean

leyline: build/leyline_tests
	./build/leyline_tests ../../data/tuning

build/leyline_tests: test_leyline.cpp $(wildcard $(SIM)/src/*.cpp) $(wildcard $(SIM)/include/wroughtwild/*.h)
	@mkdir -p build
	$(CXX) $(CXXFLAGS) -I$(SIM)/include test_leyline.cpp $(wildcard $(SIM)/src/*.cpp) -o $@
build/living_frontier_wave2_tests: test_living_frontier_wave2.cpp $(wildcard $(SIM)/src/*.cpp) $(wildcard $(SIM)/include/wroughtwild/*.h)
	@mkdir -p build
	$(CXX) $(CXXFLAGS) -I$(SIM)/include test_living_frontier_wave2.cpp $(wildcard $(SIM)/src/*.cpp) -o $@
build/living_frontier_wave3_tests: test_living_frontier_wave3.cpp living_frontier_published.inc worldgen_fingerprint.inc $(wildcard $(SIM)/src/*.cpp) $(wildcard $(SIM)/src/worldgen_*.inc) $(wildcard $(SIM)/include/wroughtwild/*.h)
	@mkdir -p build
	$(CXX) $(CXXFLAGS) -I$(SIM)/include test_living_frontier_wave3.cpp $(wildcard $(SIM)/src/*.cpp) -o $@
build/resonance_tests: test_resonance.cpp $(wildcard $(SIM)/src/*.cpp) $(wildcard $(SIM)/src/worldgen_*.inc) $(wildcard $(SIM)/include/wroughtwild/*.h)
	@mkdir -p build
	$(CXX) $(CXXFLAGS) -I$(SIM)/include test_resonance.cpp $(wildcard $(SIM)/src/*.cpp) -o $@
build/laboratory_tests: test_laboratory.cpp $(wildcard $(SIM)/src/*.cpp) $(wildcard $(SIM)/src/worldgen_*.inc) $(wildcard $(SIM)/include/wroughtwild/*.h)
	@mkdir -p build
	$(CXX) $(CXXFLAGS) -I$(SIM)/include test_laboratory.cpp $(wildcard $(SIM)/src/*.cpp) -o $@
build/pairing_tests: test_pairing.cpp $(wildcard $(SIM)/src/*.cpp) $(wildcard $(SIM)/src/worldgen_*.inc) $(wildcard $(SIM)/include/wroughtwild/*.h)
	@mkdir -p build
	$(CXX) $(CXXFLAGS) -I$(SIM)/include test_pairing.cpp $(wildcard $(SIM)/src/*.cpp) -o $@
build/central_tests: test_central.cpp $(wildcard $(SIM)/src/*.cpp) $(wildcard $(SIM)/src/worldgen_*.inc) $(wildcard $(SIM)/include/wroughtwild/*.h)
	@mkdir -p build
	$(CXX) $(CXXFLAGS) -I$(SIM)/include test_central.cpp $(wildcard $(SIM)/src/*.cpp) -o $@
build/laboratory_experiment_tests: test_laboratory_experiment.cpp $(wildcard $(SIM)/src/*.cpp) $(wildcard $(SIM)/src/worldgen_*.inc) $(wildcard $(SIM)/include/wroughtwild/*.h)
	@mkdir -p build
	$(CXX) $(CXXFLAGS) -I$(SIM)/include test_laboratory_experiment.cpp $(wildcard $(SIM)/src/*.cpp) -o $@
test: $(BIN) build/leyline_tests build/living_frontier_wave2_tests build/living_frontier_wave3_tests build/resonance_tests build/laboratory_tests build/pairing_tests build/central_tests build/laboratory_experiment_tests
	./$(BIN) ../../data/tuning
	./build/leyline_tests ../../data/tuning
	./build/living_frontier_wave2_tests ../../data/tuning
	./build/living_frontier_wave3_tests ../../data/tuning
	./build/resonance_tests ../../data/tuning
	./build/laboratory_tests ../../data/tuning
	./build/pairing_tests ../../data/tuning
	./build/central_tests ../../data/tuning
	./build/laboratory_experiment_tests ../../data/tuning

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
