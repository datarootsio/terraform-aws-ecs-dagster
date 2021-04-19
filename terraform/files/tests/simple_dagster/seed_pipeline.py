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


@repository
def syncing_pipelines():
    return [syncing_pipeline]