import Config

if System.get_env("PHX_SERVER") do
  config :forge, ForgeWeb.Endpoint, server: true
end

config :forge, ForgeWeb.Endpoint, http: [port: String.to_integer(System.get_env("PORT", "4000"))]

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :forge, Forge.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT", "4000"))
  scheme = System.get_env("PHX_SCHEME", "http")
  url_port = if scheme == "https" && port == 443, do: [], else: [port: port]

  config :forge, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  extra_hosts =
    System.get_env("PHX_EXTRA_HOSTS", "")
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)

  allowed_origins =
    (["//#{host}"] ++ Enum.map(extra_hosts, &"//#{&1}"))
    |> Enum.uniq()

  config :forge, ForgeWeb.Endpoint,
    url: [host: host, scheme: scheme] ++ url_port,
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0}
    ],
    check_origin: allowed_origins,
    secret_key_base: secret_key_base
end
