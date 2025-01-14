defmodule LorxWeb.ScheduleControllerTest do
  use LorxWeb.ConnCase

  import Lorx.ManagementFixtures

  @create_attrs %{temp: 120.5, start_time: ~T[14:00:00], end_time: ~T[14:00:00]}
  @update_attrs %{temp: 456.7, start_time: ~T[15:01:01], end_time: ~T[15:01:01]}
  @invalid_attrs %{temp: nil, start_time: nil, end_time: nil}

  describe "index" do
    test "lists all schedules", %{conn: conn} do
      conn = get(conn, ~p"/schedules")
      assert html_response(conn, 200) =~ "Listing Schedules"
    end
  end

  describe "new schedule" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/schedules/new")
      assert html_response(conn, 200) =~ "New Schedule"
    end
  end

  describe "create schedule" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/schedules", schedule: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/schedules/#{id}"

      conn = get(conn, ~p"/schedules/#{id}")
      assert html_response(conn, 200) =~ "Schedule #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/schedules", schedule: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Schedule"
    end
  end

  describe "edit schedule" do
    setup [:create_schedule]

    test "renders form for editing chosen schedule", %{conn: conn, schedule: schedule} do
      conn = get(conn, ~p"/schedules/#{schedule}/edit")
      assert html_response(conn, 200) =~ "Edit Schedule"
    end
  end

  describe "update schedule" do
    setup [:create_schedule]

    test "redirects when data is valid", %{conn: conn, schedule: schedule} do
      conn = put(conn, ~p"/schedules/#{schedule}", schedule: @update_attrs)
      assert redirected_to(conn) == ~p"/schedules/#{schedule}"

      conn = get(conn, ~p"/schedules/#{schedule}")
      assert html_response(conn, 200)
    end

    test "renders errors when data is invalid", %{conn: conn, schedule: schedule} do
      conn = put(conn, ~p"/schedules/#{schedule}", schedule: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Schedule"
    end
  end

  describe "delete schedule" do
    setup [:create_schedule]

    test "deletes chosen schedule", %{conn: conn, schedule: schedule} do
      conn = delete(conn, ~p"/schedules/#{schedule}")
      assert redirected_to(conn) == ~p"/schedules"

      assert_error_sent 404, fn ->
        get(conn, ~p"/schedules/#{schedule}")
      end
    end
  end

  defp create_schedule(_) do
    schedule = schedule_fixture()
    %{schedule: schedule}
  end
end
