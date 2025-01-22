defmodule Lorx.DeviceStateTest do
  alias Lorx.Management.Device
  alias Lorx.DeviceState
  alias Lorx.Management.Schedule
  use ExUnit.Case
  import Mock

  defp stub(temp, target_temp, status) do
    [
      {DeviceClient, [],
       [
         get_temp: fn _ip -> temp end,
         get_status: fn _ip -> status end,
         switch_on: fn _ip -> :heating end,
         switch_off: fn _ip -> :idle end
       ]},
      {Lorx.Management, [],
       [
         list_schedules: fn _id ->
           [
             %Schedule{
               temp: target_temp,
               start_time: DateTime.add(DateTime.utc_now(), -10),
               end_time: DateTime.add(DateTime.utc_now(), +10),
               device_id: 1
             }
           ]
         end
       ]}
    ]
  end

  def initial_state(prev_temp, status) do
    %DeviceState{
      id: 1,
      device: %Device{id: 1, ip: "0.0.0.0"},
      schedules: [],
      prev_temp: prev_temp,
      temp: 0,
      status: status
    }
  end

  test "current_temp=18 target_temp=20 status=:idle => should switch on" do
    with_mocks stub(18, 20, :idle) do
      new_state =
        DeviceState.update_state(initial_state(0, :idle))

      assert new_state.status == :heating
      assert new_state.temp == 18
      assert_called(DeviceClient.switch_on("0.0.0.0"))
    end
  end

  test "current_temp=18 target_temp=20 status=:heating => should do nothing" do
    with_mocks stub(18, 20, :heating) do
      new_state =
        DeviceState.update_state(initial_state(18, :heating))

      assert new_state.status == :heating

      assert_not_called(DeviceClient.switch_on("0.0.0.0"))
    end
  end

  test "current_temp=18 target_temp=17 status=:heating => should switch off" do
    with_mocks stub(18, 17, :heating) do
      new_state =
        DeviceState.update_state(initial_state(17, :heating))

      assert new_state.status == :idle

      assert_called(DeviceClient.switch_off("0.0.0.0"))
    end
  end
end
