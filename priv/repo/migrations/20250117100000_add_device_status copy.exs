defmodule Lorx.Repo.Migrations.AddDeviceStatus do
  use Ecto.Migration

  def change do
    alter table(:temperature_history) do
      add :device_status, :string
      add :target_temp, :float
    end
  end
end
