defmodule Lorx.Management.Schedule do
  use Ecto.Schema
  import Ecto.Changeset
  alias Lorx.Management.Device

  schema "schedules" do
    field :temp, :float
    field :start_time, :time
    field :end_time, :time
    belongs_to :device, Device
    field :days, {:array, :boolean}

    timestamps(type: :utc_datetime)
  end

  def changeset(schedule, attrs) do
    schedule
    |> cast(attrs, [:start_time, :end_time, :temp, :device_id, :days])
    |> validate_required([:start_time, :end_time, :temp, :device_id])
    |> validate_change(:days, fn :days, days ->
      if length(days || []) == 7, do: [], else: [days: "must have exactly 7 elements"]
    end)
  end
end
