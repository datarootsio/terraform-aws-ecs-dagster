package test

import (
	"testing"
    "fmt"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)


func getDefaultTerraformOptions(t *testing.T, resource_group_name string) (*terraform.Options, error) {
	//tempTestFolder := testStructure.CopyTerraformFolderToTemp(t, "..", ".")

	terraformOptions := &terraform.Options{
		TerraformDir:       "../examples",
		Vars:               map[string]interface{}{},
    }

	terraformOptions.Vars["resource_group_name"] = resource_group_name
	return terraformOptions, nil
}


func TestTerraformHelloWorldExample(t *testing.T) {
    resource_group_name := "test_123"
    options, err := getDefaultTerraformOptions(t, resource_group_name)
	assert.NoError(t, err)
    // terraform destroy => when test completes
	defer terraform.Destroy(t, options)
	fmt.Println("Running: terraform init && terraform apply")
	_, err = terraform.InitE(t, options)
	assert.NoError(t, err)
	_, err = terraform.PlanE(t, options)
	assert.NoError(t, err)
	_, err = terraform.ApplyE(t, options)
	assert.NoError(t, err)

	// if there are terraform errors, do nothing
	if err == nil {
		fmt.Println("Terraform apply returned no error, continuing")
	}
}
