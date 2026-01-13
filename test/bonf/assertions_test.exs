defmodule Bonf.AssertionsTest do
  use ExUnit.Case
  use Bonf.CustomAssertions, repo: Bonf.AssertionsTest.MockRepo

  # Test helpers - simulate counters
  defp get_counter(key) do
    Process.get(key, 0)
  end

  defp increment_counter(key, amount) do
    current = get_counter(key)
    Process.put(key, current + amount)
  end

  defp reset_counters do
    Process.put(:counter_a, 0)
    Process.put(:counter_b, 0)
  end

  # Mock schemas and repo for schema-based tests
  defmodule FakeSchema1 do
    defstruct [:id]
  end

  defmodule FakeSchema2 do
    defstruct [:id]
  end

  defmodule MockRepo do
    def count(schema) do
      Process.get({:schema_count, schema}, 0)
    end
  end

  defp set_schema_count(schema, count) do
    Process.put({:schema_count, schema}, count)
  end

  defp increment_schema_count(schema, amount) do
    current = MockRepo.count(schema)
    set_schema_count(schema, current + amount)
  end

  defp reset_schema_counts do
    set_schema_count(FakeSchema1, 0)
    set_schema_count(FakeSchema2, 0)
  end

  describe "assert_equal_dt" do
    test "works with second precision" do
      a = ~U[2023-05-23 20:37:21Z]
      b = ~U[2023-05-23 20:37:22Z]

      refute a == b
      assert_equal_dt(a, b)
    end

    test "works with microsecond precision" do
      a = ~U[2023-09-01 08:46:08.501961Z]
      b = ~U[2023-09-01 08:46:08.341961Z]

      refute a == b
      assert_equal_dt(a, b)
    end
  end

  describe "assert_difference/3 (function-based)" do
    setup do
      reset_counters()
      :ok
    end

    test "passes when counter increases by expected amount" do
      assert_difference(fn -> get_counter(:counter_a) end, 1, fn ->
        increment_counter(:counter_a, 1)
      end)
    end

    test "passes when counter decreases by expected amount" do
      Process.put(:counter_a, 10)

      assert_difference(fn -> get_counter(:counter_a) end, -5, fn ->
        increment_counter(:counter_a, -5)
      end)
    end

    test "passes when counter doesn't change and delta is 0" do
      assert_difference(fn -> get_counter(:counter_a) end, 0, fn ->
        :ok
      end)
    end

    test "fails when counter changes by different amount" do
      assert_raise ExUnit.AssertionError,
                   ~r/expected count to change by 3 but changed by 1/,
                   fn ->
                     assert_difference(fn -> get_counter(:counter_a) end, 3, fn ->
                       increment_counter(:counter_a, 1)
                     end)
                   end
    end

    test "works with complex expressions" do
      Process.put(:counter_a, 5)
      Process.put(:counter_b, 10)

      assert_difference(fn -> get_counter(:counter_a) + get_counter(:counter_b) end, 7, fn ->
        increment_counter(:counter_a, 3)
        increment_counter(:counter_b, 4)
      end)
    end
  end

  describe "assert_no_difference/2 (function-based)" do
    setup do
      reset_counters()
      :ok
    end

    test "passes when counter doesn't change" do
      Process.put(:counter_a, 5)

      assert_no_difference(fn -> get_counter(:counter_a) end, fn ->
        :ok
      end)
    end

    test "fails when counter changes" do
      assert_raise ExUnit.AssertionError,
                   ~r/expected count to change by 0 but changed by 1/,
                   fn ->
                     assert_no_difference(fn -> get_counter(:counter_a) end, fn ->
                       increment_counter(:counter_a, 1)
                     end)
                   end
    end
  end

  describe "assert_difference/2 (schema-based)" do
    setup do
      reset_schema_counts()
      :ok
    end

    test "passes when single schema count increases" do
      assert_difference(%{FakeSchema1 => 1}, fn ->
        increment_schema_count(FakeSchema1, 1)
      end)
    end

    test "passes when single schema count decreases" do
      set_schema_count(FakeSchema1, 10)

      assert_difference(%{FakeSchema1 => -3}, fn ->
        increment_schema_count(FakeSchema1, -3)
      end)
    end

    test "passes when multiple schemas change by different amounts" do
      assert_difference(%{FakeSchema1 => 2, FakeSchema2 => 3}, fn ->
        increment_schema_count(FakeSchema1, 2)
        increment_schema_count(FakeSchema2, 3)
      end)
    end

    test "passes when schema count doesn't change (delta = 0)" do
      set_schema_count(FakeSchema1, 5)

      assert_difference(%{FakeSchema1 => 0}, fn ->
        :ok
      end)
    end

    test "fails when schema count changes by wrong amount" do
      assert_raise ExUnit.AssertionError,
                   ~r/expected Bonf.AssertionsTest.FakeSchema1 count to change by 5, but changed by 2/,
                   fn ->
                     assert_difference(%{FakeSchema1 => 5}, fn ->
                       increment_schema_count(FakeSchema1, 2)
                     end)
                   end
    end

    test "works with multiple schemas where some don't change" do
      set_schema_count(FakeSchema2, 10)

      assert_difference(%{FakeSchema1 => 1, FakeSchema2 => 0}, fn ->
        increment_schema_count(FakeSchema1, 1)
      end)
    end
  end

  describe "assert_no_difference/2 (schema-based)" do
    setup do
      reset_schema_counts()
      :ok
    end

    test "passes when single schema count doesn't change" do
      set_schema_count(FakeSchema1, 5)

      assert_no_difference([FakeSchema1], fn ->
        :ok
      end)
    end

    test "passes when multiple schema counts don't change" do
      set_schema_count(FakeSchema1, 3)
      set_schema_count(FakeSchema2, 7)

      assert_no_difference([FakeSchema1, FakeSchema2], fn ->
        :ok
      end)
    end

    test "fails when any schema count changes" do
      assert_raise ExUnit.AssertionError,
                   ~r/expected Bonf.AssertionsTest.FakeSchema1 count to change by 0, but changed by 1/,
                   fn ->
                     assert_no_difference([FakeSchema1, FakeSchema2], fn ->
                       increment_schema_count(FakeSchema1, 1)
                     end)
                   end
    end
  end
end
