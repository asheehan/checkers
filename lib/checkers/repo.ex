defmodule Checkers.Repo do
  use Ecto.Repo,
    otp_app: :checkers,
    adapter: Ecto.Adapters.SQLite3
end
