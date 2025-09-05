import logging
import azure.functions as func
import random
import json
import datetime
import os

from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient


def estimate_pi(num_samples: int) -> float:
    inside_circle = 0
    for _ in range(num_samples):
        x, y = random.random(), random.random()
        if x * x + y * y <= 1.0:
            inside_circle += 1
    return 4 * inside_circle / num_samples


def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("Python HTTP trigger function for PI estimation started.")

    samples = req.params.get("samples")
    save = req.params.get("save")  # save = "true" или "false"

    if not samples:
        try:
            req_body = req.get_json()
        except ValueError:
            req_body = {}
        samples = req_body.get("samples")
        save = req_body.get("save", save)

    try:
        samples = int(samples)
    except (TypeError, ValueError):
        samples = 10000  # default

    save = str(save).lower() == "true"

    pi_estimate = estimate_pi(samples)

    result = {
        "method": "Monte Carlo",
        "samples": samples,
        "pi_estimate": pi_estimate,
        "saved": save
    }

    if save:
        try:
            account_url = f"https://{os.environ['STORAGE_ACCOUNT_NAME']}.blob.core.windows.net"
            credential = DefaultAzureCredential()

            blob_service_client = BlobServiceClient(account_url=account_url, credential=credential)
            container_client = blob_service_client.get_container_client("functions")

            timestamp = datetime.datetime.utcnow().strftime("%Y%m%d-%H%M%S")
            blob_name = f"pi-result-{timestamp}.json"

            container_client.upload_blob(
                name=blob_name,
                data=json.dumps(result, ensure_ascii=False, indent=2),
                overwrite=True
            )

            logging.info(f"Result saved to blob: {blob_name}")
        except Exception as e:
            logging.error(f"Failed to save result to blob: {e}")

    return func.HttpResponse(
        json.dumps(result, ensure_ascii=False, indent=2),
        mimetype="application/json",
        status_code=200
    )
