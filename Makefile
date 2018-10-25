.PHONY: test tidy clean
.SILENT: tidy

# list of all make targets excluding 'tidy'
TIDY_ARGS := $(filter-out tidy,$(MAKECMDGOALS))
# list of all make targets excluding 'critic'
CRITIC_ARGS := $(filter-out critic,$(MAKECMDGOALS))
# list stages changes
STAGED_LIST := $(shell git diff --staged --name-only | grep '\(.pm\|.pl\)')

all:
	@echo "Supported: test, tidy [module]"

test:
	prove -I./site_lib -r t/

tidy:
	(test -n "$(TIDY_ARGS)" && echo "Tidy $(TIDY_ARGS)" && perltidy -pro=ci/etc/perltidy.conf $(TIDY_ARGS)) || \
	( \
	test -n "$(STAGED_LIST)" && echo "Tidy $(STAGED_LIST)" && perltidy -pro=ci/etc/perltidy.conf $(STAGED_LIST) ) || \
	echo "Nothing to check"

critic:
	(test -n "$(CRITIC_ARGS)" && echo "Critic $(CRITIC_ARGS)" && \
	PERL5LIB=$(PERL5LIB):ci/site_lib perlcritic --cruel --profile ./ci/etc/perlcritic.conf --verbose 8 --program-extensions '.pl .t .MySQL .Oracle .CQL .SQLite .psgi' $(CRITIC_ARGS) ) || \
	echo "Nothing to check"

clean:
	find . -name '*.bak' -exec rm {} \;
