package test

import (
	"fmt"
	"net/http"
	"testing"

	"github.com/PuerkitoBio/goquery"

	"github.com/aws/aws-sdk-go/service/ecs"
	"github.com/aws/aws-sdk-go/service/iam"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	testStructure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"strings"
	"time"
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
	httpStatusCodeMaxRetries := 20
	amountOfConsecutiveGetsToBeHealthy := 3
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
	// There should only be one task running, the dagster task
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
			dagsterTask := describeTasks.Tasks[0]
			containers := dagsterTask.Containers

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

		fmt.Println("Doing HTTP request/checking health")

		protocol := "https"
		dagsterAlbDNS := terraform.Output(t, options, "dagster_dns_record")

		if options.Vars["use_https"] == false {
			protocol = "http"
		}

		if options.Vars["route53_zone_name"] == "" {
			dagsterAlbDNS = terraform.Output(t, options, "dagster_alb_dns")
		}

		fmt.Printf("%s\n", dagsterAlbDNS)

		dagsterURL := fmt.Sprintf("%s://%s", protocol, dagsterAlbDNS)

		fmt.Printf("Trying to reach %s...\n", dagsterURL)

		var amountOfConsecutiveHealthyChecks int
		var res *http.Response
		for i := 0; i < httpStatusCodeMaxRetries; i++ {
			fmt.Printf("Doing HTTP request to dagster webservice, try... %d\n", i)
			res, err = http.Get(dagsterURL)
			if res != nil && err == nil {
				fmt.Println(res.StatusCode)
				if res.StatusCode >= 200 && res.StatusCode < 400 {
					amountOfConsecutiveHealthyChecks++
					fmt.Println("Webservice is healthy")
				} else {
					amountOfConsecutiveHealthyChecks = 0
					fmt.Println("Webservice is NOT healthy")
				}

				if amountOfConsecutiveHealthyChecks == amountOfConsecutiveGetsToBeHealthy {
					break
				}
			}
			time.Sleep(retrySleepTime)
		}

		if res != nil {
			assert.Equal(t, true, res.StatusCode >= 200 && res.StatusCode < 400)
			assert.Equal(t, amountOfConsecutiveGetsToBeHealthy, amountOfConsecutiveHealthyChecks)

			if res.StatusCode >= 200 && res.StatusCode < 400 {
				fmt.Println("Getting the actual HTML code")
				defer res.Body.Close()
				doc, err := goquery.NewDocumentFromReader(res.Body)
				fmt.Println("Getting the the title of the website to confirm there's content there")
				title := doc.Find("title").Text()
				fmt.Printf("The title of the website is %s\n", title)
				assert.Equal(t, "Dagit", title)
				assert.NoError(t, err)
			}
		}
	}
}

func getDefaultTerraformOptions(t *testing.T, resourcePrefix string, resourceSuffix string) (*terraform.Options, error) {
	tempTestFolder := testStructure.CopyTerraformFolderToTemp(t, "..", "./tests/test_module")

	terraformOptions := &terraform.Options{
		TerraformDir: tempTestFolder,
		Vars:         map[string]interface{}{},
	}
	terraformOptions.Vars["resource_prefix"] = resourcePrefix
	terraformOptions.Vars["resource_suffix"] = resourceSuffix
	terraformOptions.Vars["dagster_config_bucket"] = AddPreAndSuffix("bucket", resourcePrefix, resourceSuffix)

	return terraformOptions, nil
}

func TestTerraformDagsterModule(t *testing.T) {

	resourcePrefix := "dtr"
	resourceSuffix := strings.ToLower(random.UniqueId())
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
