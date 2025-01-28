defmodule Lorx.ManagementFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lorx.Management` context.
  """

  @doc """
  Generate a schedule.
  """
  def schedule_fixture(attrs \\ %{}) do
    {:ok, schedule} =
      attrs
      |> Enum.into(%{
        device_id: 1,
        days: ["true", "true", "true", "true", "true", "true", "true"],
        end_time: ~T[14:00:00],
        start_time: ~T[14:00:00],
        temp: 120.5
      })
      |> Lorx.Management.create_schedule()

    schedule
  end

  @doc """
  Generate a device.
  """
  def device_fixture(attrs \\ %{}) do
    {:ok, device} =
      attrs
      |> Enum.into(%{
        ip: "some ip",
        name: "some name"
      })
      |> Lorx.Management.create_device()

    device
  end
end
