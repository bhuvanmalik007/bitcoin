defmodule Bitcoin do
  def start(users, noMiners, noTransactions, initialBalance) do
    # users = 5
    # noTransactions = 10
    {:ok, blockChainPID} = BlockChainGenServer.start_link()
    IO.puts("state: #{inspect(GenServer.call(blockChainPID, {:getBlockChain}))}")
    Registry.start_link(keys: :unique, name: :node_store)

    verificationAccumulatorPID = spawn(Bitcoin, :verificationAccumulator,  [0, users, blockChainPID, blockChainPID, [], []])

    minersList = Enum.reduce(1..noMiners, [], fn _, acc ->
      pid = spawn(Miner, :miningNode, [blockChainPID, verificationAccumulatorPID, 0])
      acc ++ [pid]
    end)

    transactionAutomatorPID = spawn(Bitcoin, :transactionAutomator, [users, noTransactions, 0, self()])

    for i <- 1..users do
      {:ok, {priv, pub}} = RsaEx.generate_keypair("512")
      WalletGenServer.start_link(i, priv, pub, initialBalance, minersList, transactionAutomatorPID)
    end

    send transactionAutomatorPID, {:startTransaction}

    receive do
      {:allTransactionsDone} -> {:allTransactionsDone}
    end

  end

  def transactionAutomator(users, noTransactions, counter, caller) do
    receive do
      {:startTransaction} ->
        IO.puts("#{inspect(users)} #{inspect(noTransactions)} #{inspect(counter)}")
        cond do
          (counter + 1) <= noTransactions  ->
            pair = Enum.to_list(pairs(2, users, MapSet.new()))
            IO.puts("Transaction happening between: #{inspect(pair)}")
            sendersPID = WalletGenServer.pidRetriever(Enum.at(pair, 0))
            receiversPID = WalletGenServer.pidRetriever(Enum.at(pair, 1))
            receiversWallet = GenServer.call(receiversPID, {:getWallet})
            receiversPK = Map.get(receiversWallet,"publicKey")
            GenServer.call(sendersPID, {:initiateTransaction, [sendersPID, receiversPK]})
            transactionAutomator(users, noTransactions, counter + 1, caller)
          true ->
            IO.puts("All transactions successfully completed.")
            finalBalances = Enum.reduce(1..users, %{}, fn i, acc ->
              walletPID = WalletGenServer.pidRetriever(i)
              wallet = GenServer.call(walletPID, {:getWallet})
              balance = Map.get(wallet, "btc")
              Map.put(acc, :"wallet no #{inspect(i)}", balance)
            end)
            IO.puts("FINAL BALANCES: #{inspect(finalBalances)}")
            send caller, {:allTransactionsDone}
        end
      {:transactionEnded} ->
          send self(), {:startTransaction}
          transactionAutomator(users, noTransactions, counter, caller)
      end
  end

  def pairs(num, participants, map_set) do
    if num == MapSet.size(map_set) do
      map_set
    else
      x = Enum.random(Enum.to_list(1..participants))
      map_set = MapSet.put(map_set,x)
      pairs(num,participants,map_set)
    end
  end

  def verificationAccumulator(receiveCounter, counterLimit, blockChainPID, senderPID, minersList, decisionsList) do
    receive do
      {:ok, senderPID, minersList} ->
        for i<-1..Registry.count(:node_store) do
          walletPID = WalletGenServer.pidRetriever(i)
          GenServer.call(walletPID, {:verifyBlockChain, [self(), blockChainPID]})
        end
        Bitcoin.verificationAccumulator(0, counterLimit, blockChainPID, senderPID, minersList, [])
      {:ok, receiveDecision} ->
        cond do
          receiveCounter + 1 < counterLimit  ->
            decisionsList = decisionsList ++ [receiveDecision]
            Bitcoin.verificationAccumulator(receiveCounter + 1, counterLimit,  blockChainPID, senderPID, minersList, decisionsList)
          receiveCounter + 1 == counterLimit  ->
           fraud =  Enum.any?(decisionsList, fn x -> x == false end)
           blockChain = GenServer.call(blockChainPID, {:getBlockChain})
           if(fraud) do
              for i <- 0..(length(minersList) - 1) do
                send Enum.at(minersList, i), {:decrementPointer}
              end
              List.delete_at(blockChain, length(blockChain) - 1)
              Bitcoin.verificationAccumulator(0, counterLimit,  blockChainPID, senderPID, minersList, [])
            else
              latestBlock = Enum.at(blockChain, length(blockChain) - 1)
              transactionData = Map.get(latestBlock, :transactionData)
              receiversPK = Map.get(transactionData, "receiversPK")
              btc = Map.get(transactionData, "btc")
              GenServer.cast(senderPID, {:decrementBTC, btc})
              for i <- 1..Registry.count(:node_store) do
                walletPID = WalletGenServer.pidRetriever(i)
                GenServer.cast(walletPID, {:checkTransactionReceiver, btc, receiversPK})
              end
              Bitcoin.verificationAccumulator(0, counterLimit,  blockChainPID, senderPID, minersList, [])
           end
    end
  end
end
end
