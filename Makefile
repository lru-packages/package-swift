NAME=swift
VERSION=3.0.1
EPOCH=1
ITERATION=1
PREFIX=/usr/local
LICENSE=Apache-2.0
VENDOR="Swift Core Team"
MAINTAINER="Ryan Parman"
DESCRIPTION="Swift is a general-purpose programming language built using a modern approach to safety, performance, and software design patterns."
URL=https://swift.org
RHEL=$(shell rpm -q --queryformat '%{VERSION}' centos-release)

# https://swift.org/source-code/
# http://www.swiftprogrammer.info/swift_centos_1.html
# https://github.com/FedoraSwift/fedora-swift

#-------------------------------------------------------------------------------

all: info clean install-deps compile
# all: info clean install-deps compile install-tmp package move

#-------------------------------------------------------------------------------

.PHONY: info
info:
	@ echo "NAME:        $(NAME)"
	@ echo "VERSION:     $(VERSION)"
	@ echo "EPOCH:       $(EPOCH)"
	@ echo "ITERATION:   $(ITERATION)"
	@ echo "PREFIX:      $(PREFIX)"
	@ echo "LICENSE:     $(LICENSE)"
	@ echo "VENDOR:      $(VENDOR)"
	@ echo "MAINTAINER:  $(MAINTAINER)"
	@ echo "DESCRIPTION: $(DESCRIPTION)"
	@ echo "URL:         $(URL)"
	@ echo "RHEL:        $(RHEL)"
	@ echo " "

#-------------------------------------------------------------------------------

.PHONY: clean
clean:
	rm -Rf /tmp/installdir* swift*/ blocksruntime/ build/ clang/ cmark/ compiler-rt/ llbuild/ lldb/ llvm/ ninja/

#-------------------------------------------------------------------------------

.PHONY: install-deps
install-deps:

	yum -y remove cmake;

	yum -y install \
		clang \
		clang-analyzer \
		cmake3 \
		gcc-c++ \
		git \
		icu \
		libbsd-devel \
		libcurl-devel \
		libedit-devel \
		libicu-devel \
		libuuid-devel \
		libxml2-devel \
		llvm-ocaml-devel \
		ncurses-devel \
		ncurses-libs \
		ninja-build \
		ocaml \
		openssl-devel \
		pkgconfig \
		python-devel \
		python27-devel \
		python3-devel \
		sqlite-devel \
		swig \
		uuid-devel \
	;

	cd /bin && \
		ln -s ./cmake3 ./cmake;

	pip install --upgrade pip sphinx;

	# Addresses the libblocksruntime-dev dependency for Ubuntu
	git clone -q https://github.com/mackyle/blocksruntime.git --recursive;
	cd blocksruntime && \
		git checkout b5c5274daf1e0e46ecc9ad8f6f69889bce0a0a5d && \
		./buildlib && \
		env prefix=$(PREFIX) ./installlib \
	;

	# Addresses the ninja-build dependency for Ubuntu
	git clone -q -b release https://github.com/ninja-build/ninja.git;

	# Make Cmake 3 the default for `cmake`
	alternatives --install /usr/local/bin/cmake cmake /bin/cmake3 100

#-------------------------------------------------------------------------------

.PHONY: compile
compile:
	git clone -q -b swift-$(VERSION)-RELEASE https://github.com/apple/swift.git;
	cd swift && \
		./utils/update-checkout --clone && \
		./utils/build-script -r \
	;

#-------------------------------------------------------------------------------

.PHONY: install-tmp
install-tmp:
	mkdir -p /tmp/installdir-$(NAME)-$(VERSION);
	cd ruby && \
		make install DESTDIR=/tmp/installdir-$(NAME)-$(VERSION);

#-------------------------------------------------------------------------------

.PHONY: package
package:

	# Libs package
	fpm \
		-f \
		-s dir \
		-t rpm \
		-n $(NAME)-libs \
		-v $(VERSION) \
		-C /tmp/installdir-$(NAME)-$(VERSION) \
		-m $(MAINTAINER) \
		--epoch $(EPOCH) \
		--iteration $(ITERATION) \
		--license $(LICENSE) \
		--vendor $(VENDOR) \
		--prefix / \
		--url $(URL) \
		--description $(DESCRIPTION) \
		--rpm-defattrdir 0755 \
		--rpm-digest md5 \
		--rpm-compression gzip \
		--rpm-os linux \
		--rpm-changelog CHANGELOG.txt \
		--rpm-dist el$(RHEL) \
		--rpm-auto-add-directories \
		usr/local/lib \
	;

	# Main package
	fpm \
		-f \
		-d "$(NAME)-libs = $(EPOCH):$(VERSION)-$(ITERATION).el$(RHEL)" \
		-s dir \
		-t rpm \
		-n $(NAME) \
		-v $(VERSION) \
		-C /tmp/installdir-$(NAME)-$(VERSION) \
		-m $(MAINTAINER) \
		--epoch $(EPOCH) \
		--iteration $(ITERATION) \
		--license $(LICENSE) \
		--vendor $(VENDOR) \
		--prefix / \
		--url $(URL) \
		--description $(DESCRIPTION) \
		--rpm-defattrdir 0755 \
		--rpm-digest md5 \
		--rpm-compression gzip \
		--rpm-os linux \
		--rpm-changelog CHANGELOG.txt \
		--rpm-dist el$(RHEL) \
		--rpm-auto-add-directories \
		usr/local/bin \
	;

	# Development package
	fpm \
		-f \
		-d "$(NAME) = $(EPOCH):$(VERSION)-$(ITERATION).el$(RHEL)" \
		-s dir \
		-t rpm \
		-n $(NAME)-devel \
		-v $(VERSION) \
		-C /tmp/installdir-$(NAME)-$(VERSION) \
		-m $(MAINTAINER) \
		--epoch 1 \
		--iteration $(ITERATION) \
		--license $(LICENSE) \
		--vendor $(VENDOR) \
		--prefix / \
		--url $(URL) \
		--description $(DESCRIPTION) \
		--rpm-defattrdir 0755 \
		--rpm-digest md5 \
		--rpm-compression gzip \
		--rpm-os linux \
		--rpm-changelog CHANGELOG.txt \
		--rpm-dist el$(RHEL) \
		--rpm-auto-add-directories \
		usr/local/include \
	;

	# Documentation package
	fpm \
		-f \
		-d "$(NAME) = $(EPOCH):$(VERSION)-$(ITERATION).el$(RHEL)" \
		-s dir \
		-t rpm \
		-n $(NAME)-doc \
		-v $(VERSION) \
		-C /tmp/installdir-$(NAME)-$(VERSION) \
		-m $(MAINTAINER) \
		--epoch 1 \
		--iteration $(ITERATION) \
		--license $(LICENSE) \
		--vendor $(VENDOR) \
		--prefix / \
		--url $(URL) \
		--description $(DESCRIPTION) \
		--rpm-defattrdir 0755 \
		--rpm-digest md5 \
		--rpm-compression gzip \
		--rpm-os linux \
		--rpm-changelog CHANGELOG.txt \
		--rpm-dist el$(RHEL) \
		--rpm-auto-add-directories \
		usr/local/share \
	;

#-------------------------------------------------------------------------------

.PHONY: move
move:
	mv *.rpm /vagrant/repo/
