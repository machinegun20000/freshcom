defmodule Freshcom.AccountProjector do
  use Freshcom.Projector
  use Commanded.Projections.Ecto, name: "b1c31ad3-44f9-43ce-a715-3b9da1926992"

  alias Freshcom.Account
  alias FCIdentity.{
    AccountCreated,
    AccountInfoUpdated
  }

  project(%AccountCreated{} = event, _metadata) do
    account = struct_merge(%Account{id: event.account_id}, event)
    Multi.insert(multi, :account, account)
  end

  def after_update(event, metadata, changes) do
    PubSub.broadcast(PubSubServer, Projector.topic(), {:projected, __MODULE__, changes.account})
    :ok
  end
end