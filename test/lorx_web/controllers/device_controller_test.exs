defmodule LorxWeb.DeviceControllerTest do
  use LorxWeb.ConnCase

  import Lorx.ManagementFixtures

  @create_attrs %{name: "some name", ip: "some ip"}
  @update_attrs %{name: "some updated name", ip: "some updated ip"}
  @invalid_attrs %{name: nil, ip: nil}

  describe "index" do
    test "lists all devices", %{conn: conn} do
      conn = get(conn, ~p"/devices")
      assert html_response(conn, 200) =~ "Listing Devices"
    end
  end

  describe "new device" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/devices/new")
      assert html_response(conn, 200) =~ "New Device"
    end
  end

  describe "create device" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/devices", device: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/devices/#{id}"

      conn = get(conn, ~p"/devices/#{id}")
      assert html_response(conn, 200) =~ "Device #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/devices", device: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Device"
    end
  end

  describe "edit device" do
    setup [:create_device]

    test "renders form for editing chosen device", %{conn: conn, device: device} do
      conn = get(conn, ~p"/devices/#{device}/edit")
      assert html_response(conn, 200) =~ "Edit Device"
    end
  end

  describe "update device" do
    setup [:create_device]

    test "redirects when data is valid", %{conn: conn, device: device} do
      conn = put(conn, ~p"/devices/#{device}", device: @update_attrs)
      assert redirected_to(conn) == ~p"/devices/#{device}"

      conn = get(conn, ~p"/devices/#{device}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, device: device} do
      conn = put(conn, ~p"/devices/#{device}", device: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Device"
    end
  end

  describe "delete device" do
    setup [:create_device]

    test "deletes chosen device", %{conn: conn, device: device} do
      conn = delete(conn, ~p"/devices/#{device}")
      assert redirected_to(conn) == ~p"/devices"

      assert_error_sent 404, fn ->
        get(conn, ~p"/devices/#{device}")
      end
    end
  end

  defp create_device(_) do
    device = device_fixture()
    %{device: device}
  end
end
