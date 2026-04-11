#!/usr/bin/env python3
"""Direct carrier tracking script. Stdlib only, no pip dependencies."""

import argparse
import json
import sys
import urllib.request
import urllib.parse
import urllib.error

OUTPUT_TEMPLATE = {
    "status": "unknown",
    "statusDescription": "Unknown",
    "estimatedDelivery": None,
    "checkpoints": [],
    "error": None,
}

STATUS_LABELS = {
    "pending": "Pending",
    "info_received": "Info Received",
    "in_transit": "In Transit",
    "out_for_delivery": "Out for Delivery",
    "delivered": "Delivered",
    "failed_attempt": "Failed Attempt",
    "exception": "Exception",
    "unknown": "Unknown",
}


def api_request(url, headers=None, data=None, method=None):
    req = urllib.request.Request(url, data=data, headers=headers or {})
    if method:
        req.method = method
    with urllib.request.urlopen(req, timeout=15) as resp:
        return json.loads(resp.read().decode())


def oauth_token(
    token_url, client_id, client_secret, grant_type="client_credentials", extra=None
):
    body = {
        "grant_type": grant_type,
        "client_id": client_id,
        "client_secret": client_secret,
    }
    if extra:
        body.update(extra)
    data = urllib.parse.urlencode(body).encode()
    headers = {"Content-Type": "application/x-www-form-urlencoded"}
    resp = api_request(token_url, headers=headers, data=data)
    return resp["access_token"]


def make_result(status, description=None, delivery=None, checkpoints=None, error=None):
    return {
        "status": status,
        "statusDescription": description or STATUS_LABELS.get(status, status),
        "estimatedDelivery": delivery,
        "checkpoints": checkpoints or [],
        "error": error,
    }


def make_checkpoint(timestamp, message, location=""):
    return {"timestamp": timestamp, "message": message, "location": location}


# DHL

DHL_STATUS_MAP = {
    "pre-transit": "info_received",
    "transit": "in_transit",
    "delivered": "delivered",
    "failure": "exception",
    "unknown": "unknown",
}


def track_dhl(tracking_number, api_key, **_):
    url = "https://api-eu.dhl.com/track/shipments?" + urllib.parse.urlencode(
        {"trackingNumber": tracking_number}
    )
    headers = {"DHL-API-Key": api_key, "Accept": "application/json"}
    resp = api_request(url, headers=headers)

    shipments = resp.get("shipments", [])
    if not shipments:
        return make_result("unknown", error="No shipment found")

    shipment = shipments[0]
    raw_status = shipment.get("status", {}).get("statusCode", "unknown").lower()
    status = DHL_STATUS_MAP.get(raw_status, "unknown")

    delivery = None
    edd = shipment.get("estimatedTimeOfDelivery")
    if edd:
        delivery = edd if isinstance(edd, str) else None

    checkpoints = []
    for event in shipment.get("events", []):
        loc_parts = []
        loc = event.get("location", {}).get("address", {})
        for key in ("city", "countryCode"):
            val = loc.get(key)
            if val:
                loc_parts.append(val)
        checkpoints.append(
            make_checkpoint(
                event.get("timestamp", ""),
                event.get("description", ""),
                ", ".join(loc_parts),
            )
        )

    return make_result(status, delivery=delivery, checkpoints=checkpoints)


# FedEx

FEDEX_STATUS_MAP = {
    "PU": "in_transit",
    "IT": "in_transit",
    "OD": "out_for_delivery",
    "DL": "delivered",
    "DE": "exception",
    "CA": "exception",
    "SE": "exception",
    "DP": "in_transit",
    "AR": "in_transit",
    "CD": "exception",
    "HL": "exception",
}


def track_fedex(tracking_number, client_id, client_secret, **_):
    token = oauth_token(
        "https://apis.fedex.com/oauth/token",
        client_id,
        client_secret,
    )

    headers = {
        "Authorization": "Bearer " + token,
        "Content-Type": "application/json",
        "X-locale": "en_US",
    }
    payload = json.dumps(
        {
            "trackingInfo": [
                {"trackingNumberInfo": {"trackingNumber": tracking_number}}
            ],
            "includeDetailedScans": True,
        }
    ).encode()
    resp = api_request(
        "https://apis.fedex.com/track/v1/trackingnumbers", headers=headers, data=payload
    )

    results = resp.get("output", {}).get("completeTrackResults", [])
    if not results:
        return make_result("unknown", error="No tracking result")
    track_result = results[0].get("trackResults", [{}])[0]

    raw_code = track_result.get("latestStatusDetail", {}).get("code", "")
    status = FEDEX_STATUS_MAP.get(raw_code, "unknown")
    description = track_result.get("latestStatusDetail", {}).get("description", "")

    delivery = None
    edds = track_result.get("estimatedDeliveryTimeWindow", {})
    if edds.get("window", {}).get("ends"):
        delivery = edds["window"]["ends"][:10]

    checkpoints = []
    for event in track_result.get("scanEvents", []):
        loc_parts = []
        loc = event.get("scanLocation", {})
        for key in ("city", "stateOrProvinceCode", "countryCode"):
            val = loc.get(key)
            if val:
                loc_parts.append(val)
        checkpoints.append(
            make_checkpoint(
                event.get("date", ""),
                event.get("eventDescription", ""),
                ", ".join(loc_parts),
            )
        )

    return make_result(
        status, description=description, delivery=delivery, checkpoints=checkpoints
    )


# UPS

UPS_STATUS_MAP = {
    "M": "info_received",
    "P": "in_transit",
    "I": "in_transit",
    "O": "out_for_delivery",
    "D": "delivered",
    "X": "exception",
    "RS": "exception",
    "MV": "in_transit",
}


def track_ups(tracking_number, client_id, client_secret, **_):
    token = oauth_token(
        "https://onlinetools.ups.com/security/v1/oauth/token",
        client_id,
        client_secret,
    )

    url = "https://onlinetools.ups.com/api/track/v1/details/" + urllib.parse.quote(
        tracking_number
    )
    headers = {
        "Authorization": "Bearer " + token,
        "Accept": "application/json",
        "transId": "noctalia",
        "transactionSrc": "noctalia",
    }
    resp = api_request(url, headers=headers)

    packages = resp.get("trackResponse", {}).get("shipment", [{}])[0].get("package", [])
    if not packages:
        return make_result("unknown", error="No package found")
    pkg = packages[0]

    raw_type = pkg.get("currentStatus", {}).get("type", "")
    status = UPS_STATUS_MAP.get(raw_type, "unknown")
    description = pkg.get("currentStatus", {}).get("description", "")

    delivery = None
    del_date = pkg.get("deliveryDate", [{}])
    if del_date and del_date[0].get("date"):
        d = del_date[0]["date"]
        delivery = f"{d[:4]}-{d[4:6]}-{d[6:8]}" if len(d) == 8 else d

    checkpoints = []
    for activity in pkg.get("activity", []):
        loc_parts = []
        loc = activity.get("location", {}).get("address", {})
        for key in ("city", "stateProvince", "country"):
            val = loc.get(key)
            if val:
                loc_parts.append(val)
        ts = (
            activity.get("date", "") + "T" + activity.get("time", "")
            if activity.get("time")
            else activity.get("date", "")
        )
        checkpoints.append(
            make_checkpoint(
                ts,
                activity.get("status", {}).get("description", ""),
                ", ".join(loc_parts),
            )
        )

    return make_result(
        status, description=description, delivery=delivery, checkpoints=checkpoints
    )


# USPS

USPS_STATUS_MAP = {
    "AC": "info_received",
    "OF": "info_received",
    "IT": "in_transit",
    "AT": "in_transit",
    "OD": "out_for_delivery",
    "DL": "delivered",
    "AL": "exception",
    "DE": "failed_attempt",
    "UN": "unknown",
    "NA": "pending",
}


def track_usps(tracking_number, consumer_key, consumer_secret, **_):
    token = oauth_token(
        "https://api.usps.com/oauth2/v3/token",
        consumer_key,
        consumer_secret,
    )

    url = "https://api.usps.com/tracking/v3/tracking/" + urllib.parse.quote(
        tracking_number
    )
    headers = {"Authorization": "Bearer " + token, "Accept": "application/json"}
    resp = api_request(url, headers=headers)

    tracking = (
        resp.get("trackingNumber") or resp.get("trackResults", [{}])[0]
        if resp.get("trackResults")
        else resp
    )
    if not tracking:
        return make_result("unknown", error="No tracking data")

    raw_code = ""
    if isinstance(tracking, dict):
        raw_code = tracking.get("statusCategory", "")
    status = USPS_STATUS_MAP.get(raw_code, "unknown")
    description = (
        tracking.get("statusSummary", "") if isinstance(tracking, dict) else ""
    )

    delivery = None
    if isinstance(tracking, dict) and tracking.get("expectedDeliveryDate"):
        delivery = tracking["expectedDeliveryDate"]

    checkpoints = []
    events = tracking.get("trackingEvents", []) if isinstance(tracking, dict) else []
    for event in events:
        loc_parts = []
        for key in ("eventCity", "eventState", "eventCountry"):
            val = event.get(key)
            if val:
                loc_parts.append(val)
        ts = event.get("eventTimestamp") or event.get("eventDate", "")
        checkpoints.append(
            make_checkpoint(
                ts,
                event.get("eventType", ""),
                ", ".join(loc_parts),
            )
        )

    return make_result(
        status, description=description, delivery=delivery, checkpoints=checkpoints
    )


CARRIERS = {
    "dhl": track_dhl,
    "fedex": track_fedex,
    "ups": track_ups,
    "usps": track_usps,
}


def main():
    parser = argparse.ArgumentParser(description="Track a package by carrier")
    parser.add_argument("carrier", choices=CARRIERS.keys())
    parser.add_argument("trackingNumber")
    parser.add_argument("--api-key", default="")
    parser.add_argument("--client-id", default="")
    parser.add_argument("--client-secret", default="")
    parser.add_argument("--consumer-key", default="")
    parser.add_argument("--consumer-secret", default="")
    args = parser.parse_args()

    try:
        result = CARRIERS[args.carrier](
            args.trackingNumber,
            api_key=args.api_key,
            client_id=args.client_id,
            client_secret=args.client_secret,
            consumer_key=args.consumer_key,
            consumer_secret=args.consumer_secret,
        )
    except urllib.error.HTTPError as e:
        body = ""
        try:
            body = e.read().decode()
        except Exception:
            pass
        result = make_result("unknown", error=f"HTTP {e.code}: {body[:200]}")
    except Exception as e:
        result = make_result("unknown", error=str(e))

    json.dump(result, sys.stdout)


if __name__ == "__main__":
    main()
