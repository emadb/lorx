defmodule Lorx.ManagementTest do
  use Lorx.DataCase

  alias Lorx.Management

  describe "schedules" do
    alias Lorx.Management.Schedule

    import Lorx.ManagementFixtures

    @invalid_attrs %{
      temp: nil,
      start_time: nil,
      end_time: nil,
      days: [true, true, true, true, true, true, true]
    }

    test "list_schedules/0 returns all schedules" do
      device = device_fixture()
      schedule = schedule_fixture(%{device_id: device.id})
      assert Management.list_schedules() == [schedule]
    end

    test "get_schedule!/1 returns the schedule with given id" do
      device = device_fixture()
      schedule = schedule_fixture(%{device_id: device.id})
      assert Management.get_schedule!(schedule.id) == schedule
    end

    test "create_schedule/1 with valid data creates a schedule" do
      device = device_fixture()

      valid_attrs = %{
        device_id: device.id,
        temp: 120.5,
        start_time: ~T[14:00:00],
        end_time: ~T[14:00:00],
        days: ["true", "true", "true", "true", "true", "true", "true"]
      }

      assert {:ok, %Schedule{} = schedule} = Management.create_schedule(valid_attrs)
      assert schedule.temp == 120.5
      assert schedule.start_time == ~T[14:00:00]
      assert schedule.end_time == ~T[14:00:00]
    end

    test "create_schedule/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Management.create_schedule(@invalid_attrs)
    end

    test "update_schedule/2 with valid data updates the schedule" do
      device = device_fixture()
      schedule = schedule_fixture(%{device_id: device.id})
      update_attrs = %{temp: 456.7, start_time: ~T[15:01:01], end_time: ~T[15:01:01]}

      assert {:ok, %Schedule{} = schedule} = Management.update_schedule(schedule, update_attrs)
      assert schedule.temp == 456.7
      assert schedule.start_time == ~T[15:01:01]
      assert schedule.end_time == ~T[15:01:01]
    end

    test "update_schedule/2 with invalid data returns error changeset" do
      device = device_fixture()
      schedule = schedule_fixture(%{device_id: device.id})
      assert {:error, %Ecto.Changeset{}} = Management.update_schedule(schedule, @invalid_attrs)
      assert schedule == Management.get_schedule!(schedule.id)
    end

    test "delete_schedule/1 deletes the schedule" do
      device = device_fixture()
      schedule = schedule_fixture(%{device_id: device.id})
      assert {:ok, %Schedule{}} = Management.delete_schedule(schedule)
      assert_raise Ecto.NoResultsError, fn -> Management.get_schedule!(schedule.id) end
    end

    test "change_schedule/1 returns a schedule changeset" do
      device = device_fixture()
      schedule = schedule_fixture(%{device_id: device.id})
      assert %Ecto.Changeset{} = Management.change_schedule(schedule)
    end
  end

  describe "devices" do
    alias Lorx.Management.Device

    import Lorx.ManagementFixtures

    @invalid_attrs %{name: nil, ip: nil}

    test "list_devices/0 returns all devices" do
      device = device_fixture()
      assert Management.list_devices() == [device]
    end

    test "get_device!/1 returns the device with given id" do
      device = device_fixture()
      assert Management.get_device!(device.id) == device
    end

    test "create_device/1 with valid data creates a device" do
      valid_attrs = %{name: "some name", ip: "some ip"}

      assert {:ok, %Device{} = device} = Management.create_device(valid_attrs)
      assert device.name == "some name"
      assert device.ip == "some ip"
    end

    test "create_device/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Management.create_device(@invalid_attrs)
    end

    test "update_device/2 with valid data updates the device" do
      device = device_fixture()
      update_attrs = %{name: "some updated name", ip: "some updated ip"}

      assert {:ok, %Device{} = device} = Management.update_device(device, update_attrs)
      assert device.name == "some updated name"
      assert device.ip == "some updated ip"
    end

    test "update_device/2 with invalid data returns error changeset" do
      device = device_fixture()
      assert {:error, %Ecto.Changeset{}} = Management.update_device(device, @invalid_attrs)
      assert device == Management.get_device!(device.id)
    end

    test "delete_device/1 deletes the device" do
      device = device_fixture()
      assert {:ok, %Device{}} = Management.delete_device(device)
      assert_raise Ecto.NoResultsError, fn -> Management.get_device!(device.id) end
    end

    test "change_device/1 returns a device changeset" do
      device = device_fixture()
      assert %Ecto.Changeset{} = Management.change_device(device)
    end
  end
end
