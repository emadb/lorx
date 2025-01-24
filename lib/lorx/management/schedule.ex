defmodule Lorx.Management.Schedule do
  use Ecto.Schema
  import Ecto.Changeset

  schema "schedules" do
    field :temp, :float
    field :start_time, :time
    field :end_time, :time
    field :device_id, :id

    timestamps(type: :utc_datetime)
  end

  def changeset(schedule, attrs) do
    schedule
    |> cast(attrs, [:start_time, :end_time, :temp, :device_id])
    |> validate_required([:start_time, :end_time, :temp, :device_id])
  end
end
