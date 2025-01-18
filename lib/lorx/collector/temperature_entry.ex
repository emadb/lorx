defmodule Lorx.Collector.TemperatureEntry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "temperature_history" do
    field :device_id, :integer
    field :timestamp, :utc_datetime
    field :temp, :float
    field :device_status, Ecto.Atom
    field :target_temp, :float

    timestamps(type: :utc_datetime)
  end

  def changeset(device, attrs) do
    device
    |> cast(attrs, [:device_id, :timestamp, :temp])
    |> validate_required([:device_id, :timestamp, :temp])
  end
end
