require "../spec_helper.cr"
require "../support/nodes.cr"
require "../support/interpret.cr"

# Tests for invocations and clause resolution rely on multiple clauses already
# being defined in the Interpreter. These constants act as preludes that can be
# loaded to ensure a consistent setup for each test.
FOO_DEFS = %q(
  def foo
    :no_args
  end

  def foo(1)
    :one_literal
  end

  def foo(nil)
    :nil_literal
  end

  def foo(a)
    :one_arg
  end

  def foo(a, b)
    :two_args
  end

  def foo(a, &block)
    :one_arg_with_block
  end

  def foo(&block)
    :block
  end

  def foo(1, 2, *rest)
    :trailing_splat
  end

  def foo(*head, 3, 4)
    :leading_splat
  end

  def foo(1, *mid, 4)
    :middle_splat
  end

  def foo(*all)
    :splat_all
  end
)

MODULE_DEFS = %q(
  defmodule Foo
    def foo(a)
      :one_arg
    end

    def bar
      :bar
    end
  end

  defmodule Foo
    def foo(a, b)
      :two_args
    end
  end
)

TYPE_DEFS = %q(
  deftype Foo
    defstatic foo
      :static_foo
    end

    def foo
      :instance_foo
    end
  end
)


private def it_invokes(prelude, call, expected)
  itr = parse_and_interpret(prelude)
  # Running the prelude will leave the last definition on the stack. For
  # clarity in the tests, the stack is cleared of any existing values before
  # making any assertions.
  itr.stack.clear
  it_interprets(call, [expected] of Myst::Value, itr)
end

describe "Interpreter - Invocation" do
  it_invokes FOO_DEFS, "foo", val(:no_args)

  it_invokes FOO_DEFS, "foo(1)",      val(:one_literal)
  it_invokes FOO_DEFS, "foo(nil)",    val(:nil_literal)
  it_invokes FOO_DEFS, "foo(2)",      val(:one_arg)
  it_invokes FOO_DEFS, "foo(1, 2)",   val(:two_args)
  it_invokes FOO_DEFS, "foo { }",     val(:block)
  it_invokes FOO_DEFS, "foo(1) { }",  val(:one_arg_with_block)
  it_invokes FOO_DEFS, "foo(2) { }",  val(:one_arg_with_block)
  # In this case, multiple clauses match this call, but because the clause
  # with the trailing splat appears first, it is selected.
  it_invokes FOO_DEFS, "foo(1, 2, 3, 4)",         val(:trailing_splat)
  it_invokes FOO_DEFS, "foo(nil, nil, 3, 4)",     val(:leading_splat)
  it_invokes FOO_DEFS, "foo(1, nil, nil, 4)",     val(:middle_splat)
  it_invokes FOO_DEFS, "foo(nil, nil, nil, nil)", val(:splat_all)


  it_invokes MODULE_DEFS, "Foo.foo(1)",     val(:one_arg)
  it_invokes MODULE_DEFS, "Foo.foo(1, 2)",  val(:two_args)
  it_invokes MODULE_DEFS, "Foo.bar",        val(:bar)

  it_invokes TYPE_DEFS, "Foo.foo",    val(:static_foo)
  it_invokes TYPE_DEFS, "%Foo{}.foo", val(:instance_foo)
end
