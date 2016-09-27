.PHONY: install build build_dart build_dataset build_go

build: build_dataset build_go build_dart

build_dataset: dist/national_elb

dist/national_elb: make_dataset/geodata/national_elb
	mkdir -p dist/national_elb
	cp -vr make_dataset/geodata/national_elb/ dist/national_elb/
	touch dist/national_elb

make_dataset/geodata/national_elb:
	# PLEASE ensure you comply with the license on http://www.aec.gov.au/Electorates/gis/index.htm
	$(MAKE) -C make_dataset build

build_go: serve

# Building ./serve is not necessary for uploading to appengine but building it locally should prevent any surprises
# and also allows running the application without appengine dependencies.
serve: $(wildcard runlocal/*.go) $(wildcard go_backend/*.go)
	go get -v -d . ./runlocal
	go build -o ./serve runlocal/main.go

# TODO: currently not incremental.
build_dart:
	$(MAKE) -C dart_frontend build

install: build
	appcfg.py update app.yaml
