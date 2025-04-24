import json

def load_verifiers(config_path="/etc/verifier-config/verifiers_config.json"):
  with open(config_path) as f:
      config = json.load(f)
  return config.get("verifiers", [])
