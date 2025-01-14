defmodule LorxWeb.ScheduleController do
  use LorxWeb, :controller

  alias Lorx.Management
  alias Lorx.Management.Schedule

  def index(conn, _params) do
    schedules = Management.list_schedules()
    render(conn, :index, schedules: schedules)
  end

  def new(conn, _params) do
    devices = Management.list_devices()
    changeset = Management.change_schedule(%Schedule{})
    render(conn, :new, changeset: changeset, devices: devices)
  end

  def create(conn, %{"schedule" => schedule_params}) do
    case Management.create_schedule(schedule_params) do
      {:ok, schedule} ->
        conn
        |> put_flash(:info, "Schedule created successfully.")
        |> redirect(to: ~p"/schedules/#{schedule}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    schedule = Management.get_schedule!(id)
    render(conn, :show, schedule: schedule)
  end

  def edit(conn, %{"id" => id}) do
    devices = Management.list_devices()
    schedule = Management.get_schedule!(id)
    changeset = Management.change_schedule(schedule)
    render(conn, :edit, schedule: schedule, changeset: changeset, devices: devices)
  end

  def update(conn, %{"id" => id, "schedule" => schedule_params}) do
    schedule = Management.get_schedule!(id)

    case Management.update_schedule(schedule, schedule_params) do
      {:ok, schedule} ->
        conn
        |> put_flash(:info, "Schedule updated successfully.")
        |> redirect(to: ~p"/schedules/#{schedule}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, schedule: schedule, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    schedule = Management.get_schedule!(id)
    {:ok, _schedule} = Management.delete_schedule(schedule)

    conn
    |> put_flash(:info, "Schedule deleted successfully.")
    |> redirect(to: ~p"/schedules")
  end
end
