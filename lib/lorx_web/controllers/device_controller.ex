defmodule LorxWeb.DeviceController do
  use LorxWeb, :controller

  alias Lorx.Management
  alias Lorx.Management.Device

  def index(conn, _params) do
    devices = Management.list_devices()
    render(conn, :index, devices: devices)
  end

  def new(conn, _params) do
    changeset = Management.change_device(%Device{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"device" => device_params}) do
    case Management.create_device(device_params) do
      {:ok, device} ->
        conn
        |> put_flash(:info, "Device created successfully.")
        |> redirect(to: ~p"/devices/#{device}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    device = Management.get_device!(id)
    render(conn, :show, device: device)
  end

  def edit(conn, %{"id" => id}) do
    device = Management.get_device!(id)
    changeset = Management.change_device(device)
    render(conn, :edit, device: device, changeset: changeset)
  end

  def update(conn, %{"id" => id, "device" => device_params}) do
    device = Management.get_device!(id)

    case Management.update_device(device, device_params) do
      {:ok, device} ->
        conn
        |> put_flash(:info, "Device updated successfully.")
        |> redirect(to: ~p"/devices/#{device}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, device: device, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    device = Management.get_device!(id)
    {:ok, _device} = Management.delete_device(device)

    conn
    |> put_flash(:info, "Device deleted successfully.")
    |> redirect(to: ~p"/devices")
  end
end
