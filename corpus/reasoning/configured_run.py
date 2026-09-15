"""Run an explicitly selected model using an existing service's connection.

Connection credentials stay in process memory. This is an explicit comparison,
not provider/model fallback. Remaining arguments go unchanged to reasoning.run.
"""
import argparse
import os
from pathlib import Path
import sys

from reasoning.run import load_client, main as run


def main():
    parser = argparse.ArgumentParser(description=__doc__, add_help=False)
    parser.add_argument("--connection-service", required=True)
    parser.add_argument("--model", required=True)
    parser.add_argument("--oracle-repo", type=Path, required=True)
    parser.add_argument("--reasoning-effort", choices=("none", "minimal", "low", "medium", "high", "xhigh", "max"))
    parser.add_argument("--request-timeout", type=float)
    args, remaining = parser.parse_known_args()
    if "--service" in remaining or "--role" in remaining:
        parser.error("select only one connection mechanism")
    module, _ = load_client(args.oracle_repo)
    config = module.load_running_service_config(args.connection_service, "generator", "explicit-model-comparison")
    os.environ.update(REASONING_BASE_URL=config.base_url,
                      REASONING_API_KEY=config.api_key,
                      REASONING_MODEL=args.model)
    if args.reasoning_effort is not None:
        os.environ["REASONING_EFFORT"] = args.reasoning_effort
    if args.request_timeout is not None:
        os.environ["REASONING_TIMEOUT_SECONDS"] = str(args.request_timeout)
    sys.argv = [sys.argv[0], "--oracle-repo", str(args.oracle_repo), *remaining]
    run()


if __name__ == "__main__":
    main()
