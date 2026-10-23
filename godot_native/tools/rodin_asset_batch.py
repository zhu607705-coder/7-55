#!/usr/bin/env python3
"""Bounded Rodin batch: no credentials, job keys or signed URLs in the repo.

Dry-run by default. --submit requires RODIN_API_KEY or non-echo terminal input.
Accepted task receipts are persisted before polling; a resume never resubmits.
Official API: https://docs.hyper3d.ai/en/get-started/quick-start
"""
import argparse
import datetime
import getpass
import hashlib
import json
import os
from pathlib import Path
import re
import sys
import time
import urllib.error
import urllib.request
import uuid

BASE = "https://api.hyper3d.com/api/v2"


def reference_images(asset):
    """Preserve the official one-to-five image ordering and legacy single view."""
    images = asset.get("referenceImages")
    if images is None:
        images = [asset["referenceImage"]] if asset.get("referenceImage") else []
    if not isinstance(images, list) or len(images) > 5:
        raise ValueError("Rodin accepts at most five ordered image references")
    labels = asset["request"].get("image_label", [])
    if not isinstance(labels, list) or len(labels) > len(images):
        raise ValueError("image_label must positionally match uploaded references")
    if any(label not in ("F", "FL", "FR", "B", "BL", "BR", "L", "R", "U", "D", "?") for label in labels):
        raise ValueError("Unknown Rodin view label")
    return images


def multipart_body(body, images, boundary):
    """Encode repeated images plus JSON array fields per the official API schema."""
    chunks = []
    for field, value in body.items():
        value = json.dumps(value, separators=(",", ":")) if isinstance(value, (list, dict, bool)) else str(value)
        chunks.append(f'--{boundary}\r\nContent-Disposition: form-data; name="{field}"\r\n\r\n{value}\r\n'.encode())
    for index, image in enumerate(images):
        if image.suffix.lower() != ".png" or image.read_bytes()[:8] != b"\x89PNG\r\n\x1a\n":
            raise ValueError("Image reference must be an actual PNG")
        chunks.append(f'--{boundary}\r\nContent-Disposition: form-data; name="images"; filename="reference_{index}.png"\r\nContent-Type: image/png\r\n\r\n'.encode() + image.read_bytes() + b"\r\n")
    return b"".join(chunks) + f"--{boundary}--\r\n".encode()


def save(path, value, private=False):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    fd = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600 if private else 0o644)
    with os.fdopen(fd, "w") as output:
        json.dump(value, output, ensure_ascii=False, indent=2)
        output.write("\n")
    temporary.replace(path)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("plan", type=Path)
    parser.add_argument("--submit", action="store_true")
    parser.add_argument("--state-dir", type=Path, required=True, help="Private external directory, never in a Git checkout")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--proxy")
    args = parser.parse_args()
    plan = json.loads(args.plan.read_text())
    assets = plan["assets"]
    assert len(assets) * plan["expectedCreditsPerAsset"] <= plan["maxCredits"]
    for asset in assets:
        assert re.fullmatch(r"[a-z][a-z0-9_]+", asset["id"])
        assert len(asset["request"].get("prompt", "")) <= 1024
        assert asset["request"].get("prompt") or reference_images(asset)
        for reference in reference_images(asset):
            assert (args.plan.parent / reference).is_file(), reference
        assert asset["request"]["tier"] in ("Gen-2.5-High", "Gen-2.5-Extreme-High")
        assert asset["request"]["texture_mode"] != "extreme-high"
    if not args.submit:
        print(json.dumps({"mode": "dry-run", "assets": [a["id"] for a in assets], "maximumCredits": plan["maxCredits"]}))
        return
    key = os.environ.get("RODIN_API_KEY") or getpass.getpass("Rodin API key (not saved): ")
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({"https": args.proxy}) if args.proxy else urllib.request.ProxyHandler())

    def request(endpoint, body=None, form=False, references=()):
        headers = {"Authorization": "Bearer " + key}
        if form:
            boundary = "rodin755" + uuid.uuid4().hex
            images = [(args.plan.parent / reference).resolve() for reference in references]
            data = multipart_body(body, images, boundary)
            headers["Content-Type"] = "multipart/form-data; boundary=" + boundary
        else:
            data = json.dumps(body).encode() if body is not None else None
            if data is not None:
                headers["Content-Type"] = "application/json"
        with opener.open(urllib.request.Request(BASE + endpoint, data=data, headers=headers), timeout=60) as response:
            result = json.load(response)
        if result.get("error"):
            raise RuntimeError(result["error"])
        return result

    state_path = args.state_dir / "jobs.json"
    state = json.loads(state_path.read_text()) if state_path.exists() else {"startedAt": datetime.datetime.now(datetime.timezone.utc).isoformat(), "jobs": {}}
    plan_hash = hashlib.sha256(args.plan.read_bytes()).hexdigest()
    if state.get("planSha256", plan_hash) != plan_hash:
        raise RuntimeError("Plan changed; use a different private state directory")
    state["planSha256"] = plan_hash
    if "balanceBefore" not in state:
        state["balanceBefore"] = request("/check_balance")["balance"]
        if state["balanceBefore"] < plan["maxCredits"]:
            raise RuntimeError("Insufficient existing credits for this batch")
    print(json.dumps({"balanceBefore": state["balanceBefore"], "batchMaximum": plan["maxCredits"]}), flush=True)

    for asset in assets:
        name = asset["id"]
        if name in state["jobs"]:
            if not state["jobs"][name].get("uuid"):
                raise RuntimeError(f"{name}: submission outcome uncertain; inspect account before any retry")
            continue
        # A timeout after POST may still consume credits. Mark uncertain BEFORE POST.
        state["jobs"][name] = {"status": "submission_outcome_uncertain"}
        save(state_path, state, True)
        result = request("/rodin", asset["request"], True, reference_images(asset))
        if not result.get("uuid") or not result.get("jobs", {}).get("subscription_key"):
            raise RuntimeError(f"{name}: no accepted task identifier")
        state["jobs"][name] = {"status": "submitted", "uuid": result["uuid"], "subscription_key": result["jobs"]["subscription_key"], "consumed": result.get("consumed")}
        save(state_path, state, True)
        print(json.dumps({"asset": name, "task": result["uuid"], "consumed": result.get("consumed"), "status": "submitted"}), flush=True)
        if sum(float(j.get("consumed") or 0) for j in state["jobs"].values()) > plan["maxCredits"]:
            raise RuntimeError("Unexpected billing; stop before submitting any additional assets")

    deadline = time.monotonic() + 20 * 60
    delay = 5
    while time.monotonic() < deadline:
        if all(j["status"] in ("downloaded", "failed") for j in state["jobs"].values()):
            break
        time.sleep(delay)
        for name, job in state["jobs"].items():
            if job["status"] in ("downloaded", "failed"):
                continue
            result = request("/status", {"subscription_key": job["subscription_key"]})
            statuses = [j["status"] for j in result.get("jobs", [])]
            if statuses != job.get("jobStatuses"):
                print(json.dumps({"asset": name, "jobs": statuses}), flush=True)
            job["jobStatuses"] = statuses
            if "Failed" in statuses:
                job["status"] = "failed"
            elif statuses and all(s == "Done" for s in statuses):
                available = request("/download", {"task_uuid": job["uuid"]})
                files = []
                for item in available.get("list", []):
                    filename = Path(item["name"]).name
                    if not filename or not item["url"].startswith("https://"):
                        raise RuntimeError("Invalid download metadata")
                    target = args.output / name / filename
                    target.parent.mkdir(parents=True, exist_ok=True)
                    # Never forward the API bearer token to the file host.
                    with opener.open(item["url"], timeout=120) as response, target.open("wb") as output:
                        while chunk := response.read(1024 * 1024):
                            output.write(chunk)
                    files.append({"name": filename, "bytes": target.stat().st_size, "sha256": hashlib.sha256(target.read_bytes()).hexdigest()})
                if not files:
                    raise RuntimeError("Completed task returned no downloadable files")
                job["files"] = files
                job["status"] = "downloaded"
                print(json.dumps({"asset": name, "status": "downloaded", "files": files}), flush=True)
            save(state_path, state, True)
        delay = min(delay + 5, 30)
    state["balanceAfter"] = request("/check_balance")["balance"]
    save(state_path, state, True)
    receipt = {"planSha256": plan_hash, "balanceBefore": state["balanceBefore"], "balanceAfter": state["balanceAfter"], "jobs": {name: {k: v for k, v in job.items() if k != "subscription_key"} for name, job in state["jobs"].items()}}
    save(args.output / "receipt.json", receipt)
    print(json.dumps({"balanceAfter": state["balanceAfter"], "receipt": str(args.output / "receipt.json")}), flush=True)
    if any(j["status"] != "downloaded" for j in state["jobs"].values()):
        raise RuntimeError("Batch remains incomplete; resume with the same state directory")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        # Do not emit request objects, auth headers, subscription keys or URLs.
        print(f"Rodin batch stopped: {type(error).__name__}: {error}", file=sys.stderr)
        sys.exit(1)
