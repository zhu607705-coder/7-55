extends "res://tests/test_campus_v12_connections.gd"
## Full-suite entry; CAMPUS_V12_FIXTURE still overrides the fixture for focused runs.
func default_fixture_path() -> String:
	return "res://tests/fixtures/campus_navigation_v12_regression.json"
