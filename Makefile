SHELL=/bin/bash
.PHONY: all test ci deb rpm osxpkg pkgs todo docs site

test:
	bash --version
	bats test/

ci:
	bash --version
	bats --tap test/

deb:
	fpm -t deb
	shasum -a 256 bork_*.deb > deb.shasum

rpm:
	fpm -t rpm
	shasum -a 256 bork-*.rpm > rpm.shasum

osxpkg:
	fpm -t osxpkg
	shasum -a 256 bork-*.pkg > osxpkg.shasum

pkgs:
	make -j 3 deb rpm osxpkg

todo:
	git grep --no-color TODO > todo.md

docs:
	bin/bork docgen

site:
	jekyll serve -s docs/

all: test
