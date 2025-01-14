defmodule Lorx.Repo do
  use Ecto.Repo,
    otp_app: :lorx,
    adapter: Ecto.Adapters.Postgres
end
