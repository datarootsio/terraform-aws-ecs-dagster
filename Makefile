
default: lint

tools:
	go install gotest.tools/gotestsum
	terraform init tests/test_module

fmt:
	terraform fmt
	terraform fmt tests/test_module
	go mod tidy
	gofmt -w -s tests

lint-tf: tools
	terraform fmt -check
	terraform fmt -check tests/test_module
	terraform validate tests/test_module
	tflint

lint-go:
	test -z $(gofmt -l -s test)
	go vet ./...

lint: lint-tf

test: tools lint
	go test -timeout 2h ./...

testverbose: tools lint
	go test -v -timeout 2h ./...