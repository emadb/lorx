defmodule LorxWeb.HealthController do
  use LorxWeb, :controller

  def up(conn, _params) do
    json(conn, %{status: "ok"})
  end
end