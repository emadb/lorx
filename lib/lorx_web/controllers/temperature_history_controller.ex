defmodule LorxWeb.TemperatureHistoryController do
  use LorxWeb, :controller
  alias Lorx.Management

  def index(conn, params) do
    {:ok, {from_dt, to_dt}} = parse_range(params)
    device_id = Map.get(params, "device_id")

    entries = Management.get_history(from_dt, to_dt, normalize_device(device_id))
    devices = Management.list_devices()

    render(conn, :index,
      entries: entries,
      devices: devices,
      selected_device_id: device_id,
      from: from_dt,
      to: to_dt
    )
  end

  defp parse_range(%{"from" => from, "to" => to}) when from != "" and to != "" do
    with {:ok, from_dt} <- parse_html_dt(from),
         {:ok, to_dt} <- parse_html_dt(to) do
      # Ensure correct ordering
      if DateTime.compare(from_dt, to_dt) == :gt do
        {:ok, {to_dt, from_dt}}
      else
        {:ok, {from_dt, to_dt}}
      end
    else
      _ -> default_today()
    end
  end

  defp parse_range(_), do: default_today()

  defp default_today do
    today = Date.utc_today()
    {:ok, start_dt} = DateTime.new(today, ~T[00:00:00], "Etc/UTC")
    {:ok, end_dt} = DateTime.new(today, ~T[23:59:59], "Etc/UTC")
    {:ok, {start_dt, end_dt}}
  end

  defp parse_html_dt(val) do
    # Accept formats: YYYY-MM-DDTHH:MM, YYYY-MM-DDTHH:MM:SS
    norm =
      case String.length(val) do
        # add seconds
        16 -> val <> ":00"
        19 -> val
        _ -> val
      end

    with <<date::binary-size(10), "T", time::binary-size(8)>> <- norm,
         {:ok, date} <- Date.from_iso8601(date),
         {:ok, time} <- Time.from_iso8601(time),
         {:ok, dt} <- DateTime.new(date, time, "Etc/UTC") do
      {:ok, dt}
    else
      _ -> {:error, :invalid}
    end
  end

  defp normalize_device(id) when id in [nil, "", "all"], do: nil
  defp normalize_device(id), do: String.to_integer(id)
end
