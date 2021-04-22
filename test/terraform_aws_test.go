package test

import (
	"testing"
	"fmt"
	"time"
	"strings"
	"github.com/aws/aws-sdk-go/service/ecs"
    "github.com/aws/aws-sdk-go/service/iam"
    "github.com/gruntwork-io/terratest/modules/aws"
    "github.com/gruntwork-io/terratest/modules/random"
    testStructure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func AddPreAndSuffix(resourceName string, resourcePrefix string, resourceSuffix string) string {
	if resourcePrefix == "" {
		resourcePrefix = "dataroots"
	}
	if resourceSuffix == "" {
		resourceSuffix = "dev"
	}
	return fmt.Sprintf("%s-%s-%s", resourcePrefix, resourceName, resourceSuffix)
}

func GetContainerWithName(containerName string, containers []*ecs.Container) *ecs.Container {
	for _, container := range containers {
		if *container.Name == containerName {
			return container
		}
	}
	return nil
}


func validateCluster(t *testing.T, options *terraform.Options, region string, resourcePrefix string, resourceSuffix string) {
	retrySleepTime := time.Duration(10) * time.Second
	ecsGetTaskArnMaxRetries := 20
	ecsGetTaskStatusMaxRetries := 50
	//httpStatusCodeMaxRetries := 15
	//amountOfConsecutiveGetsToBeHealthy := 3
	desiredStatusRunning := "RUNNING"
	clusterName := AddPreAndSuffix("dagster", resourcePrefix, resourceSuffix)
	serviceName := AddPreAndSuffix("dagster", resourcePrefix, resourceSuffix)
	webserverContainerName := "dagit"
	schedulerContainerName := "dagster_daemon"
	sidecarContainerName := "sidecar_container"

	iamClient := aws.NewIamClient(t, region)

	fmt.Println("Checking if roles exists")
	rolesToCheck := []string{
		AddPreAndSuffix("dagster-task-execution-role", resourcePrefix, resourceSuffix),
		AddPreAndSuffix("dagster-task-role", resourcePrefix, resourceSuffix),
	}
	for _, roleName := range rolesToCheck {
		roleInput := &iam.GetRoleInput{RoleName: &roleName}
		_, err := iamClient.GetRole(roleInput)
		assert.NoError(t, err)
	}

	fmt.Println("Checking if ecs cluster exists")
	_, err := aws.GetEcsClusterE(t, region, clusterName)
	assert.NoError(t, err)

	fmt.Println("Checking if the service is ACTIVE")
	dagsterEcsService, err := aws.GetEcsServiceE(t, region, clusterName, serviceName)
	assert.NoError(t, err)
	assert.Equal(t, "ACTIVE", *dagsterEcsService.Status)

	fmt.Println("Checking if there is 1 deployment namely the dagster one")
	assert.Equal(t, 1, len(dagsterEcsService.Deployments))

	ecsClient := aws.NewEcsClient(t, region)

	// Get all the arns of the task that are running.
	// There should only be one task running, the airflow task
	fmt.Println("Getting task arns")
	listRunningTasksInput := &ecs.ListTasksInput{
		Cluster:       &clusterName,
		ServiceName:   &serviceName,
		DesiredStatus: &desiredStatusRunning,
	}

	var taskArns []*string
	for i := 0; i < ecsGetTaskArnMaxRetries; i++ {
		fmt.Printf("Getting task arns, try... %d\n", i)

		runningTasks, _ := ecsClient.ListTasks(listRunningTasksInput)
		if len(runningTasks.TaskArns) == 1 {
			taskArns = runningTasks.TaskArns
			break
		}
		time.Sleep(retrySleepTime)
	}
	fmt.Println("Getting that there is only one task running")
	assert.Equal(t, 1, len(taskArns))

	// If there is no task running you can't do the following tests so skip them
	if len(taskArns) == 1 {
		fmt.Println("Task is running, continuing")
		describeTasksInput := &ecs.DescribeTasksInput{
			Cluster: &clusterName,
			Tasks:   taskArns,
		}

		// Wait until the 3 containers are in there desired state
		// - Sidecar container must be STOPPED to be healthy
		//   (only runs once and then stops it's an "init container")
		// - Webserver container must be RUNNING to be healthy
		// - Scheduler container must be RUNNING to be healthy
		fmt.Println("Getting container statuses")
		var webserverContainer ecs.Container
		var schedulerContainer ecs.Container
		var sidecarContainer ecs.Container
		for i := 0; i < ecsGetTaskStatusMaxRetries; i++ {
			fmt.Printf("Getting container statuses, try... %d\n", i)

			describeTasks, _ := ecsClient.DescribeTasks(describeTasksInput)
			airflowTask := describeTasks.Tasks[0]
			containers := airflowTask.Containers

			webserverContainer = *GetContainerWithName(webserverContainerName, containers)
			schedulerContainer = *GetContainerWithName(schedulerContainerName, containers)
			sidecarContainer = *GetContainerWithName(sidecarContainerName, containers)

			if *webserverContainer.LastStatus == "RUNNING" &&
				*schedulerContainer.LastStatus == "RUNNING" &&
				*sidecarContainer.LastStatus == "STOPPED" {
				break
			}
			time.Sleep(retrySleepTime)
		}
		assert.Equal(t, "RUNNING", *webserverContainer.LastStatus)
		assert.Equal(t, "RUNNING", *schedulerContainer.LastStatus)
		assert.Equal(t, "STOPPED", *sidecarContainer.LastStatus)
		fmt.Println("Containers are running correctly")
	}
}

func getDefaultTerraformOptions(t *testing.T, resourcePrefix string, resourceSuffix string) (*terraform.Options, error) {
	tempTestFolder := testStructure.CopyTerraformFolderToTemp(t, "..", ".")

	terraformOptions := &terraform.Options{
		TerraformDir:       tempTestFolder,
		Vars:               map[string]interface{}{},
    }
    terraformOptions.Vars["resource_prefix"] = resourcePrefix
    terraformOptions.Vars["resource_suffix"] = resourceSuffix
    terraformOptions.Vars["aws_availability_zone"] = "eu-west-1a"
    terraformOptions.Vars["aws_region"] = "eu-west-1"
    terraformOptions.Vars["dagster_config_bucket"] = AddPreAndSuffix("bucket", resourcePrefix, resourceSuffix)
    terraformOptions.Vars["ecs_cpu"] = 1024
    terraformOptions.Vars["ecs_memory"] = 2048
    terraformOptions.Vars["vpc"] = "vpc-0eafa6867cb3bdaa3"
    terraformOptions.Vars["public_subnet"] = []string{
    		"subnet-08da686d46e99872d",
    		"subnet-0e5bb83f963f8df0f",
    	}
    terraformOptions.Vars["rds_username"] = "dataroots"
    terraformOptions.Vars["rds_password"] = "dataroots"
    terraformOptions.Vars["rds_instance_class"] = "db.t2.micro"

	return terraformOptions, nil
}


func TestTerraformHelloWorldExample(t *testing.T) {

    resourcePrefix := "dtr"
    resourceSuffix :=  strings.ToLower(random.UniqueId())
    region := "eu-west-1"
    options, err := getDefaultTerraformOptions(t, resourcePrefix, resourceSuffix)
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
		validateCluster(t, options, region, resourcePrefix, resourceSuffix)
	}
}
