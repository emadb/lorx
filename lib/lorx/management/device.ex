defmodule Lorx.Management.Device do
  use Ecto.Schema
  import Ecto.Changeset

  schema "devices" do
    field :name, :string
    field :ip, :string
    field :enabled, :boolean

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(device, attrs) do
    device
    |> cast(attrs, [:ip, :name])
    |> validate_required([:ip, :name])
  end
end
