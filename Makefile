TOP_DIR = ../..
include $(TOP_DIR)/tools/Makefile.common
DEPLOY_RUNTIME ?= /kb/runtime
TARGET ?= /kb/deployment

BASE_NAME = InvocationService
SERVICE_SPEC = $(BASE_NAME).spec

SERVICE_PACKAGE = Bio::KBase::$(BASE_NAME)
SERVICE_PACKAGE_DIR = "lib/$(subst ::,/,$(SERVICE_PACKAGE))"
SERVICE_MODULE = "$(SERVICE_PACKAGE_DIR)/Service.pm"
VALID_COMMANDS = "$(SERVICE_PACKAGE_DIR)/ValidCommands.pm"

SERVICE = invocation
SERVICE_PORT = 7049

IRIS_WEBROOT = $(SERVICE_DIR)/webroot/Iris

#
# For debugging / development
#
# For deployment, this will be overridden by the value from the deployment config file.
#
SERVICE_URL = http://localhost:$(SERVICE_PORT)

TPAGE_ARGS = --define kb_top=$(TARGET) --define kb_runtime=$(DEPLOY_RUNTIME) --define kb_service_name=$(SERVICE) \
	--define kb_service_port=$(SERVICE_PORT) --define kb_service_url=$(SERVICE_URL)

all: build-libs bin

build-libs: $(SERVICE_MODULE) $(VALID_COMMANDS)

$(VALID_COMMANDS): ../*/COMMANDS module_commands module_commands/*
	perl gen-valid-commands.pl > $(VALID_COMMANDS)

$(SERVICE_MODULE): $(SERVICE_SPEC)
	compile_typespec \
		--impl $(SERVICE_PACKAGE)::$(BASE_NAME)Impl \
		--service $(SERVICE_PACKAGE)::Service \
		--client $(SERVICE_PACKAGE)::Client \
		--js $(BASE_NAME) \
		--py biokbase/$(BASE_NAME)/Client \
		$(SERVICE_SPEC) lib

bin: $(BIN_PERL)

deploy: build-libs deploy-client

deploy-all: deploy-service deploy-client

deploy-client: deploy-docs deploy-scripts

deploy-service: deploy-dir-service deploy-monit deploy-libs deploy-iris
	$(TPAGE) $(TPAGE_ARGS) service/start_service.tt > $(TARGET)/services/$(SERVICE)/start_service
	chmod +x $(TARGET)/services/$(SERVICE)/start_service
	$(TPAGE) $(TPAGE_ARGS) service/stop_service.tt > $(TARGET)/services/$(SERVICE)/stop_service
	chmod +x $(TARGET)/services/$(SERVICE)/stop_service

#
# Deploy the Iris interface.
# 
deploy-iris: 
	mkdir -p $(IRIS_WEBROOT)/Iris
	rsync -arv Iris/. $(IRIS_WEBROOT)
	cp lib/$(BASE_NAME).js $(IRIS_WEBROOT)/$(BASE_NAME).js
	$(TPAGE) $(TPAGE_ARGS) iris-index.html.tt > $(IRIS_WEBROOT)/iris.html
    cp Iris/splash.html > $(IRIS_WEBROOT)/index.html

deploy-monit:
	$(TPAGE) $(TPAGE_ARGS) service/process.$(SERVICE).tt > $(TARGET)/services/$(SERVICE)/process.$(SERVICE)

deploy-docs:
	mkdir -p doc
	mkdir -p $(SERVICE_DIR)/webroot
	rm -f doc/*html
	$(DEPLOY_RUNTIME)/bin/perl $(DEPLOY_RUNTIME)/bin/pod2html -t "Invocation Service API" lib/Bio/KBase/$(BASE_NAME)/$(BASE_NAME)Impl.pm > doc/invocation_api.html
	rsync -arv doc/. $(SERVICE_DIR)/webroot/.

include $(TOP_DIR)/tools/Makefile.common.rules
