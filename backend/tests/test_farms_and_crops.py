from datetime import date


def create_farm(client, headers, name="North plot"):
    response = client.post("/api/v1/farms", headers=headers, json={
        "farm_name": name,
        "land_area_acres": 2.5,
        "soil_type": "Black Cotton",
        "irrigation_source": "Canal",
    })
    assert response.status_code == 201, response.text
    return response.json()


def test_farm_crud_and_private_ownership(client, register_farmer):
    owner, owner_headers, _, _ = register_farmer("Farm Owner")
    other, other_headers, _, _ = register_farmer("Other Farmer")
    farm = create_farm(client, owner_headers)
    farm_id = farm["id"]

    assert client.get("/api/v1/farms", headers=owner_headers).json()[0]["id"] == farm_id
    assert client.get("/api/v1/farms", headers=other_headers).json() == []
    assert client.get(f"/api/v1/farms/{farm_id}", headers=other_headers).status_code == 403
    assert client.put(f"/api/v1/farms/{farm_id}", headers=other_headers, json={"farm_name": "stolen"}).status_code == 403
    assert client.delete(f"/api/v1/farms/{farm_id}", headers=other_headers).status_code == 403

    updated = client.put(f"/api/v1/farms/{farm_id}", headers=owner_headers, json={
        "farm_name": "East plot", "irrigation_source": "Drip"
    })
    assert updated.status_code == 200
    assert updated.json()["farm_name"] == "East plot"
    assert updated.json()["farmer_id"] == owner["id"]

    deleted = client.delete(f"/api/v1/farms/{farm_id}", headers=owner_headers)
    assert deleted.status_code == 204
    assert client.get("/api/v1/farms", headers=owner_headers).json() == []
    assert other["id"] != owner["id"]


def test_crop_cycles_are_owned_and_validated(client, register_farmer):
    _, owner_headers, _, _ = register_farmer("Crop Farmer")
    _, other_headers, _, _ = register_farmer("Another Farmer")
    farm = create_farm(client, owner_headers, "Cycle farm")
    response = client.post("/api/v1/crop-cycles", headers=owner_headers, json={
        "farm_id": farm["id"],
        "crop_name": "Paddy",
        "variety": "Farmer selected",
        "sowing_date": date.today().isoformat(),
        "stage": "Sowing",
    })
    assert response.status_code == 201, response.text
    cycle_id = response.json()["id"]
    assert client.get(f"/api/v1/crop-cycles/farm/{farm['id']}", headers=owner_headers).json()[0]["id"] == cycle_id
    assert client.get(f"/api/v1/crop-cycles/farm/{farm['id']}", headers=other_headers).status_code == 403
    assert client.patch(f"/api/v1/crop-cycles/{cycle_id}", headers=other_headers, json={"stage": "Harvesting"}).status_code == 403
    assert client.delete(f"/api/v1/crop-cycles/{cycle_id}", headers=other_headers).status_code == 403

    updated = client.patch(
        f"/api/v1/crop-cycles/{cycle_id}",
        headers=owner_headers,
        json={"crop_name": "Paddy", "variety": "BPT", "sowing_date": date.today().isoformat()},
    )
    assert updated.status_code == 200, updated.text
    assert updated.json()["variety"] == "BPT"


def test_crop_cycle_deletion_removes_observations_for_owner(client, register_farmer):
    _, owner_headers, _, _ = register_farmer("Cycle Delete Owner")
    _, other_headers, _, _ = register_farmer("Cycle Delete Other")
    farm = create_farm(client, owner_headers, "Delete cycle farm")
    cycle = client.post("/api/v1/crop-cycles", headers=owner_headers, json={
        "farm_id": farm["id"],
        "crop_name": "Paddy",
        "sowing_date": date.today().isoformat(),
    }).json()
    observations_path = f"/api/v1/farm-observations/crop-cycle/{cycle['id']}"
    created = client.post(observations_path, headers=owner_headers, json={
        "observation_date": date.today().isoformat(),
        "notes": "Field inspection",
    })
    assert created.status_code == 201, created.text
    assert client.delete(f"/api/v1/crop-cycles/{cycle['id']}", headers=other_headers).status_code == 403
    assert client.delete(f"/api/v1/crop-cycles/{cycle['id']}", headers=owner_headers).status_code == 204
    assert client.get(f"/api/v1/crop-cycles/farm/{farm['id']}", headers=owner_headers).json() == []
    assert client.get(observations_path, headers=owner_headers).status_code == 404


def test_observations_persist_with_pagination_and_cycle_owner_checks(client, register_farmer):
    _, owner_headers, _, _ = register_farmer("Observation Owner")
    _, other_headers, _, _ = register_farmer("Observation Other")
    farm = create_farm(client, owner_headers, "Observation farm")
    cycle = client.post("/api/v1/crop-cycles", headers=owner_headers, json={
        "farm_id": farm["id"],
        "crop_name": "Paddy",
        "sowing_date": date.today().isoformat(),
    }).json()
    path = f"/api/v1/farm-observations/crop-cycle/{cycle['id']}"
    assert client.get(path).status_code == 401

    first = client.post(path, headers=owner_headers, json={
        "observation_date": date.today().isoformat(),
        "soil_moisture_percentage": 42.5,
        "pest_symptoms": "No visible symptoms",
        "notes": "Checked north field in the morning",
    })
    second = client.post(path, headers=owner_headers, json={"notes": "Second field check"})
    assert first.status_code == 201, first.text
    assert second.status_code == 201, second.text
    observation_id = first.json()["id"]
    assert first.json()["soil_moisture_percentage"] == 42.5
    assert len(client.get(f"{path}?limit=1", headers=owner_headers).json()) == 1

    assert client.get(path, headers=other_headers).status_code == 404
    assert client.patch(
        f"/api/v1/farm-observations/{observation_id}",
        headers=other_headers,
        json={"notes": "unauthorized edit"},
    ).status_code == 404

    updated = client.patch(
        f"/api/v1/farm-observations/{observation_id}",
        headers=owner_headers,
        json={"notes": "Updated field note"},
    )
    assert updated.status_code == 200
    assert updated.json()["notes"] == "Updated field note"
    assert updated.json()["updated_at"]
    deleted = client.delete(f"/api/v1/farm-observations/{observation_id}", headers=owner_headers)
    assert deleted.status_code == 204


def test_recommendations_use_explicit_conditions_and_owned_farm(client, register_farmer):
    _, owner_headers, _, _ = register_farmer("Recommendation Owner")
    _, other_headers, _, _ = register_farmer("Recommendation Other")
    farm = create_farm(client, owner_headers, "Recommendation farm")

    missing_conditions = client.get(f"/api/v1/crop-recommendations/{farm['id']}", headers=owner_headers)
    assert missing_conditions.status_code == 422
    response = client.get(
        f"/api/v1/crop-recommendations/{farm['id']}?season=Kharif&available_water=high",
        headers=owner_headers,
    )
    assert response.status_code == 200
    assert response.json()[0]["methodology"] == "transparent_rules"
    cross_farm = client.get(
        f"/api/v1/crop-recommendations/{farm['id']}?season=Kharif&available_water=high",
        headers=other_headers,
    )
    assert cross_farm.status_code == 403


def test_farm_and_crop_cycle_validation(client, register_farmer):
    _, headers, _, _ = register_farmer("Validation Farmer")
    invalid = client.post("/api/v1/farms", headers=headers, json={
        "farm_name": "Bad area", "land_area_acres": 0,
        "soil_type": "Black", "irrigation_source": "Rainfed",
    })
    assert invalid.status_code == 422
    assert invalid.json()["error_code"] == "VALIDATION_ERROR"
    assert client.post("/api/v1/farms", json={
        "farm_name": "No auth", "land_area_acres": 2,
        "soil_type": "Black", "irrigation_source": "Rainfed",
    }).status_code == 401
    farm = create_farm(client, headers, "Date validation farm")
    invalid_dates = client.post("/api/v1/crop-cycles", headers=headers, json={
        "farm_id": farm["id"],
        "crop_name": "Paddy",
        "sowing_date": "2026-05-20",
        "expected_harvest_date": "2026-05-19",
    })
    assert invalid_dates.status_code == 422
    blank_crop = client.post("/api/v1/crop-cycles", headers=headers, json={
        "farm_id": farm["id"],
        "crop_name": "   ",
        "sowing_date": date.today().isoformat(),
    })
    assert blank_crop.status_code == 422
