from app import app

def test_root_status_ok():
    with app.test_client() as c:
        r = c.get("/")
        assert r.status_code == 200
        assert r.get_json()["ok"] is True
