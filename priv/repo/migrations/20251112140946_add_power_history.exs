defmodule Lorx.Repo.Migrations.AddPowerHistory do
  use Ecto.Migration

  def change do
    create table(:power_history) do
      add :timestamp, :utc_datetime
      add :w, :float
      add :wh, :float

      timestamps(type: :utc_datetime)
    end
  end
end
