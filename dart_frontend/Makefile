.PHONY: format_analyze pub_get clean to_arb move_gtt_translations from_arb build

format_analyze: pub_get
	grind

pub_get:
	pub get

clean:
	rm -rf build

to_arb:
	mkdir -p /tmp/i18n
	pub run intl:extract_to_arb --output-dir=/tmp/i18n lib/i18n/messages.dart
	mv /tmp/i18n/intl_messages.arb /tmp/i18n/messages_en.arb

move_gtt_translations:
	for l in `ls -1 /tmp/i18n/translations`; do mv /tmp/i18n/translations/$$l/messages.arb /tmp/i18n/translations/messages_$$l.arb; rmdir /tmp/i18n/translations/$$l; done

from_arb:
	pub run intl:generate_from_arb lib/i18n/messages.dart /tmp/i18n/translations/messages_*.arb
	mv messages_*.dart lib/i18n

build: clean pub_get
	grind build
	mkdir -p ../dist/static/styles
	cp -v build/web/styles/*.css ../dist/static/styles/
	cp -v -r build/web/static/* ../dist/static/
	cp -v build/web/*.html ../dist/static/
	cp -v build/web/*.js ../dist/static/
	cp -v build/web/index_template/*.html ../dist/
