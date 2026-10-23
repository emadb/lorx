defmodule Lorx.Repo.Migrations.CreateExternalTempHistory do
  use Ecto.Migration

  def change do
    create table(:external_temperature_history) do
      add :timestamp, :utc_datetime
      add :temp, :float

      timestamps(type: :utc_datetime)
    end
  end
end
