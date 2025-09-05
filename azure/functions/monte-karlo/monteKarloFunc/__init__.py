import logging
import azure.functions as func
import random
import json
import datetime
import os

from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient
from azure.data.tables import TableServiceClient

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
    save = req.params.get("save")      # save = "true"/"false"
    savetab = req.params.get("savetab")  # savetab = "true"/"false"

    if not samples:
        try:
            req_body = req.get_json()
        except ValueError:
            req_body = {}
        samples = req_body.get("samples", samples)
        save = req_body.get("save", save)
        savetab = req_body.get("savetab", savetab)

    try:
        samples = int(samples)
    except (TypeError, ValueError):
        samples = 10000  # default

    save = str(save).lower() == "true"
    savetab = str(savetab).lower() == "true"

    pi_estimate = estimate_pi(samples)

    result = {
        "method": "Monte Carlo",
        "samples": samples,
        "pi_estimate": pi_estimate,
        "saved_blob": save,
        "saved_table": savetab
    }

    account_url = f"https://{os.environ['STORAGE_ACCOUNT_NAME']}.blob.core.windows.net"
    credential = DefaultAzureCredential()

    if save:
        try:
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

    if savetab:
        try:
            table_service_client = TableServiceClient(
                endpoint=f"https://{os.environ['STORAGE_ACCOUNT_NAME']}.table.core.windows.net",
                credential=credential
            )
            table_name = "functions"
            table_client = table_service_client.get_table_client(table_name)

            # Убедиться что таблица существует
            try:
                table_service_client.create_table(table_name=table_name)
            except Exception:
                pass  # таблица уже есть

            timestamp = datetime.datetime.utcnow().isoformat()
            entity = {
                "PartitionKey": "PiEstimation",
                "RowKey": timestamp.replace(":", "_"),
                "Samples": samples,
                "PiEstimate": pi_estimate,
                "CreatedAt": timestamp
            }

            table_client.upsert_entity(entity)
            logging.info(f"Result saved to table: {table_name}")
        except Exception as e:
            logging.error(f"Failed to save result to table: {e}")

    return func.HttpResponse(
        json.dumps(result, ensure_ascii=False, indent=2),
        mimetype="application/json",
        status_code=200
    )
