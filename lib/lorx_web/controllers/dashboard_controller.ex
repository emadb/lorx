defmodule LorxWeb.DashboardController do
  use LorxWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end
end
