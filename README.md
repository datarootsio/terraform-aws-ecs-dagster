# This is a Readme test

<!--- BEGIN_TF_DOCS --->
## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 0.13 |
| aws | ~> 3.12.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 3.12.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws\_availability\_zone | The availability zone of the resource. | `string` | `"eu-west-1a"` | no |
| aws\_region | The region of the aws account | `string` | `"eu-west-1"` | no |
| dagster-container-home | n/a | `string` | `"/opt"` | no |
| dagster\_config\_bucket | Dagster bucket containing the config files. | `string` | `"dagster-bucket"` | no |
| dagster\_file | The config file needed to use database and daemon with dagit. | `string` | `"dagster.yaml"` | no |
| ecs\_cpu | The amount of cpu to give to the ECS instance. | `number` | `1024` | no |
| ecs\_memory | The amount of ecs memory to give to the ECS instance. | `number` | `2048` | no |
| log\_retention | The number of days that the logs shoud live. | `number` | `7` | no |
| private\_subnet | The private subnets where the RDS and ECS reside. | `list(string)` | `[]` | no |
| public\_subnet | The public subnet where the load balancer should reside. Moreover, the ecs and rds will use these if no private subnets are defined. At least two should be provided. | `list(string)` | `[]` | no |
| rds\_deletion\_protection | n/a | `bool` | `false` | no |
| rds\_instance\_class | The type of instance class for the RDS. | `string` | `"db.t2.micro"` | no |
| rds\_password | The password to access the RDS instance. | `string` | `""` | no |
| rds\_username | The username to access the RDS instance. | `string` | `""` | no |
| resource\_prefix | The prefix of the resource to be created | `string` | `"ps"` | no |
| resource\_suffix | The suffix of the resource to be created | `string` | `"sp"` | no |
| tags | Tags to add to the created resources. | `map(string)` | <pre>{<br>  "Name": "Terraform-aws-dagster"<br>}</pre> | no |
| vpc | The id of the virtual private cloud. | `string` | `""` | no |
| workspace\_file | The config file needed to run dagit. | `string` | `"workspace.yaml"` | no |

## Outputs

No output.

<!--- END_TF_DOCS --->