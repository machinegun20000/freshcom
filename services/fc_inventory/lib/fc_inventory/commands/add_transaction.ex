defmodule FCInventory.AddTransaction do
  use TypedStruct
  use Vex.Struct

  typedstruct do
    field :request_id, String.t()
    field :requester_id, String.t()
    field :requester_type, String.t()
    field :requester_role, String.t()
    field :client_id, String.t()
    field :client_type, String.t()
    field :account_id, String.t()

    field :movement_id, String.t()
    field :line_item_id, String.t()
    field :source_batch_id, String.t()
    field :transaction_id, String.t()

    field :status, String.t()
    field :quantity, Decimal.t()
  end

  validates :movement_id, presence: true, uuid: true
  validates :line_item_id, presence: true, uuid: true
  validates :source_batch_id, presence: true, uuid: true
  validates :transaction_id, presence: true, uuid: true
  validates :quantity, presence: true
  validates :status, presence: true
end