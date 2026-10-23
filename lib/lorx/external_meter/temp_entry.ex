defmodule Lorx.ExternalMeter.TempEntry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "external_temperature_history" do
    field :timestamp, :utc_datetime
    field :temp, :float

    timestamps(type: :utc_datetime)
  end

  def changeset(device, attrs) do
    device
    |> cast(attrs, [:temp, :timestamp])
    |> validate_required([:temp, :timestamp])
  end
end
