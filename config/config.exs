use Mix.Config

# Pull the port from the environment
config :server, port: System.get_env("DIST_SERVER_PORT")
