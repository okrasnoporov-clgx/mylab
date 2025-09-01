import logging
import azure.functions as func
import random
import json

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
    if not samples:
        try:
            req_body = req.get_json()
        except ValueError:
            req_body = {}
        samples = req_body.get("samples")

    try:
        samples = int(samples)
    except (TypeError, ValueError):
        samples = 10000  # default

    pi_estimate = estimate_pi(samples)


    result = {
        "method": "Monte Carlo",
        "samples": samples,
        "pi_estimate": pi_estimate
    }

    return func.HttpResponse(
        json.dumps(result, ensure_ascii=False, indent=2),
        mimetype="application/json",
        status_code=200
    )
