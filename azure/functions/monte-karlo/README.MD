Virt ENV

python -m venv .venv
source .venv/bin/activate   # Linux/macOS
.venv\Scripts\activate      # Windows

pip install -r requirements.txt


LOCAL TEST
func start


curl "http://localhost:7071/api/monteKarloFunc?samples=50000"

azure\functions\monte-karlo\monteKarloFunc
