import boto3
from botocore.exceptions import ClientError


def get_secret(secret):
    return secret + "HELLO"