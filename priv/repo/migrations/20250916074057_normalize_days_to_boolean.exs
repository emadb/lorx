defmodule Lorx.Repo.Migrations.NormalizeDaysToBoolean do
  use Ecto.Migration

  @default_week ~w(TRUE TRUE TRUE TRUE TRUE TRUE TRUE)

  def up do
    # 1. Add new boolean[] column with default
    alter table(:schedules) do
      add :days_bool, {:array, :boolean},
        default: fragment("ARRAY[TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE]"),
        null: false
    end

    # 2. Backfill converting existing string values -> boolean
    execute("""
    UPDATE schedules
    SET days_bool = (
      SELECT ARRAY(
        SELECT CASE
                 WHEN lower(trim(val)) IN ('true','t','1','yes','y') THEN TRUE
                 ELSE FALSE
               END
        FROM unnest(days) AS val
      )
    )
    WHERE days IS NOT NULL
    """)

    # If any rows had NULL days, ensure they get the default
    execute("""
    UPDATE schedules
    SET days_bool = ARRAY[TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE]
    WHERE days_bool IS NULL
    """)

    # 3. Remove old column
    alter table(:schedules) do
      remove :days
    end

    # 4. Rename new column
    rename table(:schedules), :days_bool, to: :days
  end

  def down do
    # Reverse: recreate string array, copy back, drop boolean
    alter table(:schedules) do
      add :days_text, {:array, :string},
        default: fragment("ARRAY['true','true','true','true','true','true','true']"),
        null: false
    end

    execute("""
    UPDATE schedules
    SET days_text = (
      SELECT ARRAY(
        SELECT CASE WHEN b THEN 'true' ELSE 'false' END
        FROM unnest(days) AS b
      )
    )
    """)

    alter table(:schedules) do
      remove :days
    end

    rename table(:schedules), :days_text, to: :days
  end
end
