.PHONY: setup test lint run

setup:
python -m venv venv && . venv/bin/activate && pip install -r requirements.txt

test:
. venv/bin/activate && pytest -vv && python -m unittest discover -v || true

lint:
. venv/bin/activate && pylint superagi || true

run:
. venv/bin/activate && python main.py
