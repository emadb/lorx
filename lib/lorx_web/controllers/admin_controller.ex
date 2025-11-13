defmodule LorxWeb.AdminController do
  use LorxWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end

  def restart_devices(conn, _params) do
    Lorx.DeviceSupervisor.spawn_children()

    conn
    |> put_flash(:info, "Tutti i device sono stati riavviati con successo")
    |> redirect(to: ~p"/admin")
  end
end
