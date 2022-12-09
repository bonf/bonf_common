defmodule Bonf.CustomAssertions do
  defmacro assert_difference(count_fn, delta, run_fn) do
    quote do
      value1 = unquote(count_fn)
      unquote(run_fn).()
      value2 = unquote(count_fn)

      assert value2 == value1 + unquote(delta),
             "expected count to change by #{unquote(delta)} but changed by #{value2 - value1}"
    end
  end

  defmacro assert_no_difference(count_fn, run_fn) do
    quote do
      assert_difference(unquote(count_fn), 0, unquote(run_fn))
    end
  end
end
