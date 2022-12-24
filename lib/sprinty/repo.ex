defmodule Sprinty.Repo do
  use Ecto.Repo,
    otp_app: :sprinty,
    adapter: Ecto.Adapters.Postgres
end
