defmodule Bonf.AssertionsTest do
  use ExUnit.Case
  import Bonf.CustomAssertions

  describe "second" do
    test "assert_equal_dt" do
      a = ~U[2023-05-23 20:37:21Z]
      b = ~U[2023-05-23 20:37:22Z]

      refute a == b
      assert_equal_dt(a, b)
    end

    test "microsecond" do
      a = ~U[2023-09-01 08:46:08.501961Z]
      b = ~U[2023-09-01 08:46:08.341961Z]

      refute a == b
      assert_equal_dt(a, b)
    end
  end
end
