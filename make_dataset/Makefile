AECDATAFILE=national-midmif-09052016.zip

.PHONY: build

build: geodata/$(AECDATAFILE)
	./make_dataset.sh

geodata/$(AECDATAFILE):
	# PLEASE ensure you comply with the license on http://www.aec.gov.au/Electorates/gis/index.htm
	curl -o geodata/$(AECDATAFILE) http://www.aec.gov.au/Electorates/gis/files/$(AECDATAFILE)
