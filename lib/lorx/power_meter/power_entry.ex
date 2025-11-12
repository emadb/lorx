defmodule Lorx.PowerMeter.PowerEntry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "power_history" do
    field :timestamp, :utc_datetime
    field :w, :float
    field :wh, :float

    timestamps(type: :utc_datetime)
  end

  def changeset(device, attrs) do
    device
    |> cast(attrs, [:w, :timestamp, :wh])
    |> validate_required([:w, :timestamp, :wh])
  end
end
