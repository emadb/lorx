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

    render(conn, :new,
      changeset: changeset,
      devices: devices
    )
  end

  def create(conn, %{"schedule" => schedule_params} = params) do
    days = parse_days(params)

    case Management.create_schedule(Map.merge(schedule_params, %{"days" => days})) do
      {:ok, schedule} ->
        conn
        |> put_flash(:info, "Schedule created successfully.")
        |> redirect(to: ~p"/schedules/#{schedule}")

      {:error, %Ecto.Changeset{} = changeset} ->
        devices = Management.list_devices()
        render(conn, :new, changeset: changeset, devices: devices)
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

  defp parse_days(p) do
    %{
      "monday" => monday,
      "tuesday" => tuesday,
      "wednesday" => wednesday,
      "thursday" => thursday,
      "friday" => friday,
      "saturday" => saturday,
      "sunday" => sunday
    } = p

    [monday, tuesday, wednesday, thursday, friday, saturday, sunday]
  end

  def update(conn, %{"id" => id, "schedule" => schedule_params} = params) do
    schedule = Management.get_schedule!(id)
    days = parse_days(params)

    case Management.update_schedule(schedule, Map.merge(schedule_params, %{"days" => days})) do
      {:ok, schedule} ->
        conn
        |> put_flash(:info, "Schedule updated successfully.")
        |> redirect(to: ~p"/schedules/#{schedule}")

      {:error, %Ecto.Changeset{} = changeset} ->
        devices = Management.list_devices()
        render(conn, :edit, schedule: schedule, changeset: changeset, devices: devices)
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
