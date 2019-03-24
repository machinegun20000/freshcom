defmodule FCInventory.TransactionHandler do
  @moduledoc false

  @behaviour Commanded.Commands.Handler

  use FCBase, :command_handler

  import FCInventory.TransactionPolicy

  alias FCInventory.{
    DraftTransaction,
    PrepareTransaction,
    UpdateTransaction,
    MarkTransaction,
    CommitTransaction,
    DeleteTransaction,
    CompleteTransactionPrep,
    CompleteTransactionCommit
  }
  alias FCInventory.{
    TransactionCommitRequested,
    TransactionCommitted,
    TransactionMarked,
    TransactionDeleted
  }
  alias FCInventory.Transaction
  alias FCInventory.{Worker, System}

  def authorize(cmd, _, type) do
    case type.from(cmd._staff_) do
      nil -> {:error, {:unauthorized, :staff}}
      staff -> {:ok, %{cmd | _staff_: staff}}
    end
  end

  def handle(%Transaction{id: nil} = txn, %DraftTransaction{} = cmd) do
    cmd
    |> authorize(txn, Worker)
    |> OK.flat_map(&Transaction.draft(&1, &1._staff_))
    |> Map.put(:client_id, cmd.client_id)
    |> unwrap_ok()
  end

  def handle(_, %DraftTransaction{}), do: {:error, {:already_exist, :transaction}}
  def handle(%Transaction{id: nil}, _), do: {:error, {:not_found, :transaction}}
  def handle(%Transaction{status: "deleted"}, _), do: {:error, {:already_deleted, :transaction}}

  def handle(txn, %PrepareTransaction{} = cmd) do
    cmd
    |> authorize(txn, Worker)
    |> OK.flat_map(&Transaction.request_preparation(txn, &1._staff_))
    |> Map.put(:client_id, cmd.client_id)
    |> unwrap_ok()
  end

  def handle(txn, %CompleteTransactionPrep{} = cmd) do
    cmd
    |> authorize(txn, Worker)
    |> OK.flat_map(&Transaction.complete_preparation(txn, &1.quantity, &1._staff_))
    |> Map.put(:client_id, cmd.client_id)
    |> unwrap_ok()
  end

  def handle(txn, %UpdateTransaction{} = cmd) do
    cmd
    |> authorize(txn, Worker)
    |> OK.flat_map(&Transaction.update(txn, Map.take(&1, &1.effective_keys), &1._staff_))
    |> Map.put(:client_id, cmd.client_id)
    |> unwrap_ok()
  end

  def handle(txn, %MarkTransaction{} = cmd) do
    cmd
    |> authorize(txn, System)
    |> OK.flat_map(&Trasaction.mark(txn, &1.status, &1._staff_))
    |> Map.put(:client_id, cmd.client_id)
    |> unwrap_ok()

    # event = merge(%TransactionMarked{original_status: state.status}, state)

    # cmd
    # |> authorize(state)
    # ~> merge_to(event)
    # |> unwrap_ok()
  end

  def handle(%{status: "ready"} = state, %CommitTransaction{} = cmd) do
    event = %TransactionCommitRequested{
      stockable_id: state.stockable_id,
      source_id: state.source_id,
      destination_id: state.destination_id
    }

    cmd
    |> authorize(state)
    ~> merge_to(event)
    |> unwrap_ok()
  end

  def handle(_, %CommitTransaction{}) do
    {:error, {:validation_failed, [{:error, :status, :must_be_ready}]}}
  end

  def handle(state, %CompleteTransactionCommit{} = cmd) do
    event = merge(%TransactionCommitted{}, state)

    cmd
    |> authorize(state)
    ~> merge_to(event)
    |> unwrap_ok()
  end

  def handle(%{status: "committed"}, %DeleteTransaction{}) do
    {:error, {:validation_failed, [{:error, :status, :cannot_be_committed}]}}
  end

  def handle(state, %DeleteTransaction{} = cmd) do
    event = merge(%TransactionDeleted{}, state)

    cmd
    |> authorize(state)
    ~> merge_to(event)
    |> unwrap_ok()
  end
end