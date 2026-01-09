SHELL := /bin/bash

.PHONY: test lint format format-check clean

test:
	swift test

lint: format-check
	swiftlint

format:
	swiftformat .

format-check:
	swiftformat --lint .

clean:
	rm -rf .build
