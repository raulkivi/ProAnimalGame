# Makefile — Animal Game (GNU Prolog)

GPROLOG = gprolog

# GNU Prolog has no module system: sources are consulted in dependency order.
SRC = src/node.pl src/ui.pl src/tree.pl src/persist.pl src/main.pl
RUN_CONSULT = $(patsubst %,--consult-file %,$(SRC))

.PHONY: run test test-node test-ui test-tree test-persist clean

run:
	$(GPROLOG) $(RUN_CONSULT) --query-goal 'run_game, halt'

test: test-node test-ui test-tree test-persist

test-node:
	$(GPROLOG) --consult-file tests/harness.pl \
	           --consult-file src/node.pl \
	           --consult-file tests/test_node.pl

test-ui:
	$(GPROLOG) --consult-file tests/harness.pl \
	           --consult-file src/ui.pl \
	           --consult-file tests/test_ui.pl

test-tree:
	$(GPROLOG) --consult-file tests/harness.pl \
	           --consult-file src/node.pl \
	           --consult-file src/ui.pl \
	           --consult-file tests/scripted_io.pl \
	           --consult-file src/tree.pl \
	           --consult-file tests/test_tree.pl

test-persist:
	$(GPROLOG) --consult-file tests/harness.pl \
	           --consult-file src/node.pl \
	           --consult-file src/persist.pl \
	           --consult-file tests/test_persist.pl

clean:
	rm -f data/tree.pl data/tree.pl.tmp
