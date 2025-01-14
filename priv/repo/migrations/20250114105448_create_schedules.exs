defmodule Lorx.Repo.Migrations.CreateSchedules do
  use Ecto.Migration

  def change do
    create table(:schedules) do
      add :start_time, :time
      add :end_time, :time
      add :temp, :float
      add :device_id, references(:devices, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:schedules, [:device_id])
  end
end
