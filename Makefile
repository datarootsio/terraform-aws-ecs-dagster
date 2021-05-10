
default: lint

tools:
	go install gotest.tools/gotestsum
	terraform init test/test_module

fmt:
	terraform fmt
	terraform fmt test/test_module
	go mod tidy
	gofmt -w -s test

lint-tf: tools
	terraform fmt -check
	terraform fmt -check test/test_module
	terraform validate test/test_module
	tflint

lint-go:
	test -z $(gofmt -l -s test)
	go vet ./...

lint: lint-tf lint-go

test: tools lint
	go test -timeout 2h ./...

testverbose: tools lint
	go test -v -timeout 2h ./...