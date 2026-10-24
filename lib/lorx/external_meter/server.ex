defmodule Lorx.ExternalMeter.Server do
  use GenServer, restart: :transient

  require Logger

  alias Lorx.ExternalMeter.TempEntry
  alias Lorx.Repo

  import Ecto.Query

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_status do
    GenServer.call(__MODULE__, :get_status)
  end

  @impl true
  def init([]) do
    ip = Application.get_env(:lorx, :device)[:external_temp_ip]

    last =
      TempEntry
      |> order_by([entry], desc: entry.timestamp, desc: entry.id)
      |> limit(1)
      |> Repo.one()

    state = %{value: last && last.temp, configured?: ip not in [nil, ""]}

    if state.configured?, do: send(self(), :check_temp)

    {:ok, state}
  end

  @impl true
  def handle_info(:check_temp, state) do
    settings = Application.get_env(:lorx, :device)
    ip = settings[:external_temp_ip]

    if ip in [nil, ""] do
      {:noreply, %{state | configured?: false}}
    else
      interval = settings[:external_temp_interval] || 300_000
      Process.send_after(self(), :check_temp, interval)

      value =
        case Lorx.ExternalMeter.ApiClient.get_temp(ip) do
          {:ok, temp} ->
            save(temp)
            temp

          {:error, _} ->
            :error
        end

      Phoenix.PubSub.broadcast(
        Lorx.PubSub,
        "external_temperature",
        {:external_temperature, value}
      )

      {:noreply, %{state | value: value, configured?: true}}
    end
  end

  @impl true
  def handle_call(:get_status, _from, state) do
    {:reply, {:ok, state}, state}
  end

  defp save(temp) do
    entry = %TempEntry{
      timestamp: DateTime.utc_now() |> DateTime.truncate(:second),
      temp: temp
    }

    case Repo.insert(entry) do
      {:ok, _} -> :ok
      {:error, _} -> Logger.error("External temperature history insert failed")
    end
  rescue
    _ -> Logger.error("External temperature history insert failed")
  end
end
