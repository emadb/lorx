defmodule Lorx.Repo.Migrations.CreateSchedules do
  use Ecto.Migration

  def change do
    create table(:temperature_history) do
      add :device_id, references(:devices, on_delete: :nothing)
      add :timestamp, :utc_datetime
      add :temp, :float

      timestamps(type: :utc_datetime)
    end
  end
end
