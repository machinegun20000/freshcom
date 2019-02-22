defmodule FCInventory.Router.MarkLineItemTest do
  use FCBase.RouterCase

  alias Decimal, as: D
  alias FCInventory.Router
  alias FCInventory.MarkLineItem
  alias FCInventory.{
    MovementCreated,
    LineItemAdded,
    LineItemMarked
  }

  setup do
    cmd = %MarkLineItem{
      movement_id: uuid4(),
      line_item_id: uuid4(),
      status: "reserved"
    }

    %{cmd: cmd}
  end

  test "given valid command with authorized role", %{cmd: cmd} do
    account_id = uuid4()
    client_id = app_id("standard", account_id)
    requester_id = user_id(account_id, "goods_specialist")

    to_streams(:movement_id, "stock-movement-", [
      %MovementCreated{
        movement_id: cmd.movement_id
      },
      %LineItemAdded{
        movement_id: cmd.movement_id,
        line_item_id: cmd.line_item_id,
        status: "processing",
        quantity: D.new(5)
      }
    ])

    cmd = %{cmd | client_id: client_id, account_id: account_id, requester_id: requester_id}

    assert :ok = Router.dispatch(cmd)

    assert_receive_event(LineItemMarked, fn event ->
      assert event.status == cmd.status
      assert event.original_status == "processing"
    end)
  end
end