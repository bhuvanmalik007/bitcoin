defmodule BitcoinMain do
  def main(args) do
    args |> parse_args |> start
  end

  defp parse_args(args) do
      {_, parameters, _} = OptionParser.parse(args, switches: [ name: :string],aliases: [ h: :name])
      parameters
  end

  # Calling Bitcoin.start to initiate the building of the ecosystem and start transactions
  def start(parameters) do
    numUsers = String.to_integer(Enum.at(parameters, 0))
    numMiners = String.to_integer(Enum.at(parameters, 1))
    numTransaction = String.to_integer(Enum.at(parameters, 2))
    {walletBalance, _} = Float.parse(Enum.at(parameters, 3))
    IO.puts "\nBuilding your custom blockchain ecosystem "
    Bitcoin.start(numUsers, numMiners, numTransaction, walletBalance)
  end
end
