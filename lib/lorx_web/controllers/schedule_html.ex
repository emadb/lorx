defmodule LorxWeb.ScheduleHTML do
  use LorxWeb, :html

  embed_templates "schedule_html/*"

  @doc """
  Renders a schedule form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :devices, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def schedule_form(assigns)

  # Helpers for the schedule index UI
  @doc false
  def active_now?(%{start_time: start_time, end_time: end_time, days: days}) do
    # Normalize day flags to booleans
    flags =
      Enum.map(days, fn
        true -> true
        "true" -> true
        _ -> false
      end)

    # Determine today's index (1..7 with Monday=1)
    day_idx = Date.day_of_week(Date.utc_today()) - 1

    # If today is inactive, it's not active now
    if Enum.at(flags, day_idx) != true do
      false
    else
      # Get current local time and compare with schedule slot
      %NaiveDateTime{hour: h, minute: m, second: s} = NaiveDateTime.local_now()
      {:ok, now} = Time.new(h, m, s)

      case Time.compare(start_time, end_time) do
        :lt -> Time.compare(now, start_time) != :lt and Time.compare(now, end_time) == :lt
        _ -> Time.compare(now, start_time) != :lt or Time.compare(now, end_time) == :lt
      end
    end
  end

  @doc false
  def days_summary(days) when is_list(days) do
    flags =
      Enum.map(days, fn
        true -> true
        "true" -> true
        _ -> false
      end)

    case flags do
      [true, true, true, true, true, true, true] ->
        "Every day"

      [true, true, true, true, true, false, false] ->
        "Weekdays"

      [false, false, false, false, false, true, true] ->
        "Weekends"

      _ ->
        # Try common alternating patterns (e.g., Mon/Wed/Fri)
        labels = ~w(Mon Tue Wed Thu Fri Sat Sun)

        act =
          flags
          |> Enum.with_index()
          |> Enum.filter(fn {v, _i} -> v end)
          |> Enum.map(fn {_v, i} -> Enum.at(labels, i) end)

        if length(act) in [0, 7], do: nil, else: Enum.join(act, ", ")
    end
  end

  @doc false
  def group_schedules_by_day(schedules) do
    day_names = ["Monday", "Tuesday", "Wednesday", "Thursady", "Friday", "Saturday", "Sunday"]

    # Initialize empty map for each day
    empty_week =
      day_names
      |> Enum.with_index()
      |> Enum.into(%{}, fn {day_name, index} -> {index, %{name: day_name, schedules: []}} end)

    # Group schedules by day
    schedules
    |> Enum.reduce(empty_week, fn schedule, acc ->
      schedule.days
      |> Enum.with_index()
      |> Enum.reduce(acc, fn {is_active, day_index}, day_acc ->
        if is_active in [true, "true"] do
          schedule_with_time = %{
            start_time: schedule.start_time,
            end_time: schedule.end_time,
            temp: schedule.temp,
            id: schedule.id
          }

          update_in(day_acc[day_index].schedules, &[schedule_with_time | &1])
        else
          day_acc
        end
      end)
    end)
    |> Enum.map(fn {_index, day_data} ->
      # Sort schedules by start time for each day
      sorted_schedules = Enum.sort_by(day_data.schedules, & &1.start_time)
      %{day_data | schedules: sorted_schedules}
    end)
  end

  @doc false
  def format_time_slot(start_time, end_time) do
    start_str = Calendar.strftime(start_time, "%H:%M")
    end_str = Calendar.strftime(end_time, "%H:%M")
    "#{start_str} - #{end_str}"
  end
end
