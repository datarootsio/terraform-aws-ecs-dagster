from dagster import solid, pipeline, repository
from subprocess import run


@solid
def s3_bucket(context):
    # Remove hardcoded
    cmd = 'python -m awscli s3 sync $S3_BUCKET_NAME/ $DAGSTER_HOME'
    rc = run(args=cmd, shell=True, capture_output=True)
    context.log.info(f"Syncing result: {rc}")


@pipeline
def syncing_pipeline():
    s3_bucket()


@solid
def show_it(context):
    # Remove hardcoded
    cmd = 'ls /opt'
    rc = run(args=cmd, shell=True, capture_output=True)
    context.log.info(f"Showing result: {rc}")

@pipeline
def showit_pipeline():
    show_it()


@solid
def print_it(context):
    # Remove hardcoded
    cmd = 'cat /opt/serial_pipeline.py'
    rc = run(args=cmd, shell=True, capture_output=True)
    context.log.info(f"printing result: {rc}")


@pipeline
def printit_pipeline():
    print_it()



@repository
def syncing_pipelines():
    return [syncing_pipeline, printit_pipeline, showit_pipeline]