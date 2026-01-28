import Config

# Configure your database
config :checkers, Checkers.Repo,
  database: Path.expand("../checkers_test.db", __DIR__),
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :checkers, CheckersWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "x5rgGaBQDozY4DTKpzFeHV6IyKnFH4TIcFm9Fh1oTDsp0y5QFG6xKiXxvXxT+qDD",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true
