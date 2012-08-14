TOP_DIR = ../..
include $(TOP_DIR)/tools/Makefile.common

SERVER_SPEC = InvocationService.spec

SERVICE_MODULE = lib/Bio/KBase/InvocationService/Service.pm

SERVICE = invocation
SERVICE_PORT = 7049

TPAGE_ARGS = --define kb_top=$(TARGET) --define kb_runtime=$(DEPLOY_RUNTIME) --define kb_service_name=$(SERVICE) \
	--define kb_service_port=$(SERVICE_PORT)

all: bin server

server: $(SERVICE_MODULE)

$(SERVICE_MODULE): $(SERVER_SPEC)
	./recompile_typespec 

bin: $(BIN_PERL)

deploy: deploy-service

deploy-service: deploy-dir-service deploy-scripts deploy-libs deploy-services deploy-monit deploy-doc
deploy-client: deploy-scripts deploy-libs  deploy-doc

deploy-services:
	$(TPAGE) $(TPAGE_ARGS) service/start_service.tt > $(TARGET)/services/$(SERVICE)/start_service
	chmod +x $(TARGET)/services/$(SERVICE)/start_service
	$(TPAGE) $(TPAGE_ARGS) service/stop_service.tt > $(TARGET)/services/$(SERVICE)/stop_service
	chmod +x $(TARGET)/services/$(SERVICE)/stop_service

deploy-monit:
	$(TPAGE) $(TPAGE_ARGS) service/process.$(SERVICE).tt > $(TARGET)/services/$(SERVICE)/process.$(SERVICE)

deploy-doc:
	$(DEPLOY_RUNTIME)/bin/pod2html -t "Invocation Service API" lib/IDServerAPIImpl.pm > doc/idserver_api.html
	cp doc/*html $(SERVICE_DIR)/webroot/.

include $(TOP_DIR)/tools/Makefile.common.rules
